module Spree::Api::V3::Storefront
	class MiarzeController < Spree::Api::V2::BaseController

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
			where_criteria = { taxon_ids: @taxon_id }
			if !filter_option_values_ids.nil?
				where_criteria[:options_value_ids] = filter_option_values_ids
			end
			@all_results = Spree::Product.search("*",
		    where: where_criteria,
		    order: order_criteria,
		    page: params[:page] || 1,
		    per_page: params[:per_page] || 24
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
			render :json => {:error => e.message}
		end

		private
				
		def validate_params
			if params[:taxon_id].nil? && params[:permalink].nil?
				raise "You MUST provide taxon_id OR permalink"
			end
			key = params[:taxon_id].to_i > 0 ? params[:taxon_id].to_i : params[:permalink].strip
			if key.is_a? Integer
				taxon = Spree::Taxon.find key
			else 
				taxon = Spree::Taxon.find_by(permalink: key)
			end
			if taxon.nil?
				raise "Couldnt find taxon with #{key}"
			end	
			taxon.id					
		end
    def generate_cache_key(id)
      "pt_#{id}_cache"
    end			
    def fetch_products(product_ids)
      keys = product_ids.map { |id| generate_cache_key(id) }
      products = Rails.cache.read_multi(*keys)
      missing_ids = product_ids.reject { |id| products[generate_cache_key(id)] }
      unless missing_ids.empty?
        cache_products_service.new(missing_ids).execute
        new_products = Rails.cache.read_multi(*missing_ids.map { |id| generate_cache_key(id) })
        products.merge!(new_products)
      end

      products.values.compact
    end

		def customized_collect_taxons
		  result = Spree::Product.search(
		    '*', # Match all products (you can modify this to suit your needs)
		    where: { id: @all_data_ids }, # Filter by product IDs
		    fields: [:taxon_permalinks], # Fetch taxon data for the products
		    load: false
		  ).map(&:taxon_permalinks).flatten.uniq
		  result
		end
		def total_pages
			@all_data_ids.size / (params[:per_page] ||24)+ 1
		end
		def gather_meta_data
			meta = {
				"count": @all_results.size,
				"total_count": @all_data_ids.size,
				"total_pages": total_pages,
				"filters":{
					"option_types": customized_collect_option_types,
					"taxons": customized_collect_taxons
				}
			}
		end
		def customized_collect_option_types
			return [] if @all_data_ids.empty?
			brands = get_brands
			[{
			  "id": 1,
			  "name": "brand",
			  "presentation": "برند",
			  "option_values": brands
			}] 
		end	
    def get_brands
      keys = @all_data_ids.map { |id| "spree_brands_product_#{id}_cache" }
      brands = Rails.cache.read_multi(*keys)
      missing_ids = @all_data_ids.reject { |item| brands["spree_brands_product_#{item}_cache"] }
      unless missing_ids.empty?
        cache_brands_service.new(missing_ids).execute
        new_brands = Rails.cache.read_multi(*missing_ids.map { |id| "spree_brands_product_#{id}_cache" })
        brands.merge!(new_brands)
      end
      brands.values.compact.flatten.uniq
    end		

		def cache_brands_service
			Spree::CustomizedCaching::Brand::Cache
		end       
    def cache_products_service
      Spree::CustomizedCaching::Product::ProductTaxonCache
    end
    def prepare_option_value_ids(option_values_ids)
        return if option_values_ids.nil? || option_values_ids.to_s.blank?
      option_values_ids.to_s.split(',').map(&:to_i)
    end    
	end
end

