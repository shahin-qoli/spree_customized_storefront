module Spree::Api::V3::Storefront
	class MiarzeController < Spree::Api::V2::BaseController
		include Spree::Api::V3::GetProductsTaxon
		before_action :check_admin_role, only: [:reindex_products]
		def get_products_of_taxon
			@taxon_id = validate_params
			order_criteria = prepare_order_criteria

			base_criteria = { taxon_ids: @taxon_id }
			where_criteria = prepare_where_criteria(base_criteria)
			pagination_params = prepare_paginaton_params
			@all_results = Spree::Product.search("*",
		    where: where_criteria,
		    order: order_criteria,
		    page: pagination_params[0].to_i,
		    per_page: @per_page.to_i
		  ).map(&:id)	
		  @all_data_ids = Spree::Product.search("*",
		    where: where_criteria,
		    load: false, # Prevents loading full objects, only fetches IDs
		    fields: [:product_id] # Only fetches the product_id field
		  ).map(&:id)
			@count = @all_data_ids.size
			data = {
				:products => fetch_products(@all_results),
				:meta => gather_meta_data	
			}
			render :json => data
		rescue StandardError => e
			render :json => {:error => e.message}, status: 400
		end

		def get_product
			id = params[:id]
			slug = params[:slug]

			if !id.nil?
				product = Spree::Product.find(id.to_i)
			else
				product = Spree::Product.find_by_slug(slug)
			end
			variant_ids = product.variants.map(&:id)
      keys = variant_ids.map { |id| generate_cache_key_single_product(id) }
      variants = Rails.cache.read_multi(*keys)		
      missing_ids = variant_ids.reject { |id| variants[generate_cache_key_single_product(id)] }
      unless missing_ids.empty?
        cache_single_product_service.new(missing_ids).execute
        new_variants = Rails.cache.read_multi(*missing_ids.map { |id| generate_cache_key_single_product(id) })
        variants.merge!(new_variants)
      end
      data = variants.values.compact.map{|item| item[:data]}.flatten

      render :json => data	
 		rescue StandardError => e
			render :json => {:error => e.message}, status: 400     
		end

		def search_products
			search_param = validate_params_search
			order_criteria = prepare_order_criteria
			base_criteria = {}
			where_criteria = prepare_where_criteria(base_criteria)
			pagination_params = prepare_paginaton_params
			@all_results = Spree::Product.search(search_param,
		    where: where_criteria,
		    order: order_criteria,
		    page: pagination_params[0].to_i,
		    per_page: @per_page.to_i
		  ).map(&:id)	
		  @all_data_ids = Spree::Product.search(search_param,
		    where: where_criteria,
		    load: false # Only fetches the product_id field
		  ).map(&:id)
			@count = @all_data_ids.size
			data = {
				:products => fetch_products(@all_results),
				:meta => gather_meta_data	
			}
			render :json => data
		rescue StandardError => e
		 	render :json => {:error => e.message}, status: 400			
		end

		def reindex_products
			Spree::BrxElastic::ReindexProductsJob.perform_later
			render :json =>{:result => true}
			# if Spree::Product.reindex
			# 	render :json =>{:result => true}
			# else
			# 	render :json =>{:result => false}
			# end
 		rescue StandardError => e
			render :json => {:error => e.message}, status: 400  				
		end


		private
		def cache_single_product_service
          Spree::CustomizedCaching::Product::ProductSingleCache		
		end
	  def generate_cache_key_single_product(id)
	    	Digest::MD5::hexdigest("vi_#{id.to_s}_cache")
	  end	

	
		def prepare_order_criteria
		  order_criteria = [{ sort_priority_numeric: { order: :desc } }]
		#   case params[:sort_by]
		#   when "-price"
		#     order_criteria << { price: :desc }
		#   when "price"
		#     order_criteria << { price: :asc }
		#   end

		#   # if @taxon_id
		#   #   order_criteria << { "taxon_positions.#{@taxon_id}" => { order: :asc, unmapped_type: "long" } }
		#   # end

		# if @taxon_id
		#   order_criteria << {
		#     "taxon_positions.position" => {
		#       order: :asc,
		#       nested: {
		# 	path: "taxon_positions",
		# 	filter: {
		# 	  term: { "taxon_positions.id": @taxon_id.to_i }
		# 	}
		#       },
		#       unmapped_type: "long"
		#     }
		#   }
		# end
			p "OOOOOOOOOOOOOOOO"
			p order_criteria
		  order_criteria
		end

	  def prepare_where_criteria(where_criteria)
			filter_option_values_ids = prepare_option_value_ids(params.dig(:filter, :option_value_ids))
			filter_in_stock = params.dig(:filter, :in_stock)
			filter_price = map_prices(String(params.dig(:filter, :price)).split(','))
			if !filter_option_values_ids.nil?
				where_criteria[:options_value_ids] = filter_option_values_ids
			end
			if (!filter_in_stock.nil? && filter_in_stock.is_a?(TrueClass))
				where_criteria[:in_stock] = filter_in_stock
				where_criteria[:available] = filter_in_stock
			end
			if !filter_price.nil?
				where_criteria[:price] = { gte: filter_price.min, lte: filter_price.max }
			end

			where_criteria
	  end

	  def prepare_paginaton_params
			page = params[:page].to_i > 0 ? params[:page].to_i : 1
			@per_page =  params[:per_page].to_i > 0 ?  params[:per_page].to_i : 24 
			[page, @per_page]
	  end

    def validate_params_search
      if params[:search_term].nil?
        raise "You MUST provide search_term"
      end
      params[:search_term].strip
    end

		def check_admin_role
			user = spree_current_user
			unless user&.has_spree_role?('admin')
			  render json: { error: 'Unauthorized' }, status: :unauthorized
			end
		end
	end
end

