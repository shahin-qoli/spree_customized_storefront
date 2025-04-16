module Spree::Api::V3::Storefront
	class MiarzeController < Spree::Api::V2::BaseController
		include Spree::Api::V3::GetProductsTaxon
		def get_products_of_taxon
			@taxon_id = validate_params
			order_criteria = [{ in_stock: :desc }]
			case params[:sort_by]
			when "price"
				order_criteria << { price: :desc }
			when "-price"
				order_criteria << { price: :asc }
			else
				order_criteria << { "taxon_positions.#{@taxon_id}" => :asc }
			end
			filter_option_values_ids = prepare_option_value_ids(params.dig(:filter, :option_value_ids))
			filter_in_stock = params.dig(:filter, :in_stock)
			filter_price = map_prices(String(params.dig(:filter, :price)).split(','))
			where_criteria = { taxon_ids: @taxon_id }
			if !filter_option_values_ids.nil?
				where_criteria[:options_value_ids] = filter_option_values_ids
			end
			if (!filter_in_stock.nil? && filter_in_stock.is_a?(TrueClass))
				where_criteria[:in_stock] = filter_in_stock
			end
			if !filter_price.nil?
				where_criteria[:price] = { gte: filter_price.min, lte: filter_price.max }
			end
			page = params[:page].to_i > 0 ? params[:page].to_i : 1
			@per_page =  params[:per_page].to_i > 0 ?  params[:per_page].to_i : 24 
			@all_results = Spree::Product.search("*",
		    where: where_criteria,
		    order: order_criteria,
		    page: page,
		    per_page: @per_page
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
      
		end

		private
		def cache_single_product_service
          Spree::CustomizedCaching::Product::ProductSingleCache		
		end
	  def generate_cache_key_single_product(id)
	    	Digest::MD5::hexdigest("vi_#{id.to_s}_cache")
	   end			
	end
end

