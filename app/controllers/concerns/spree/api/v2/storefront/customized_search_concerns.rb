module Spree
  module Api
    module V2
      module Storefront
        module CustomizedSearchConcerns
        	extend ActiveSupport::Concern
          private
          def products_data
            @products_data ||= fetch_products(customized_pagination(customized_collection))
          end
          

          def customized_collection
            return @customized_collection if @customized_collection
          
            @customized_collection = customized_collection_finder.new(params: finder_params).execute(@sort_by)
            @total_count = @customized_collection.size
            @customized_collection
          end

          def get_brands
            keys = product_ids.map { |id| "spree_brands_product_#{id}_cache" }
            brands = Rails.cache.read_multi(*keys)
            missing_ids = product_ids.reject { |id| brands["spree_brands_product_#{id}_cache"] }
            unless missing_ids.empty?
              cache_brands_service.new(missing_ids).execute
              new_brands = Rails.cache.read_multi(*missing_ids.map { |id| "spree_brands_product_#{id}_cache" })
              brands.merge!(new_brands)
            end
            brands.flatten!.uniq!
          end
          
          def customized_pagination(customized_collection)
            page = params[:page].present? ? params[:page].to_i : 1
            per_page = params[:per_page].present? ? params[:per_page].to_i : 24
            @total_count = customized_collection.size
            return customized_collection if customized_collection.size < 1
            min = (page - 1) * per_page
            max = min + (per_page - 1)
            if customized_collection[min..max].nil?
              return []
            end
            customized_collection[min..max]
            
          end
          def fetch_products(product_ids)
            keys = product_ids.map { |id| "spree_customized_product_#{id}_cache" }
            products = Rails.cache.read_multi(*keys)
                     
            missing_ids = product_ids.reject { |id| products["spree_customized_product_#{id}_cache"] }
            unless missing_ids.empty?
              cache_products_service.new(missing_ids).execute
              new_products = Rails.cache.read_multi(*missing_ids.map { |id| "spree_customized_product_#{id}_cache" })
              products.merge!(new_products)
            end
            integrate_data(products.values.compact)
          end


          def integrate_data(data)
            return { data: [], included: [] } if data.empty?
          
            merged_data = { data: [], included: [] }
            unique_included = {}
          
            data.each do |d|
              merged_data[:data].concat(d[:data])
          
              d[:included].each do |item|
                unique_key = [item[:id], item[:type]]
                unique_included[unique_key] ||= item
              end
            end
          
            merged_data[:included] = unique_included.values
            merged_data
          end

          def collect_meta_data(products_data, per_page)
              count = products_data[:data].size < per_page ? products_data[:data].size : per_page 
              @total_pages = (@total_count / per_page).to_i > 0 ? (@total_count / per_page).to_i : 1
              option_types = customized_collect_option_types(products_data)
              {
                :count => count,
                :total_count => @total_count,
                :total_pages => @total_pages,
                :filters => {
                  :option_types => option_types,
                  :product_properties => []
                }
              }
          end          

          def customized_collect_option_types(products_data)
            return [] if products_data[:data].empty?
            brands = get_brands
            [{
              "id": 1,
              "name": "brand",
              "presentation": "برند",
              "option_values": get_brands
            }] 
          end


          def customized_collection_finder
            Spree::Products::CustomizedFind
          end

          def cache_products_service
            Spree::CustomizedCaching::Product::Cache
          end
          
          def cache_brands_service
            Spree::CustomizedCaching::Brand::Cache
          end
          
          def customized_collection_links(current_page)
            next_page = current_page < @total_pages ? current_page + 1 : @total_pages
            prev_page = current_page > 1 ? current_page - 1 : current_page
            {
              self: request.original_url,
              next: pagination_url(next_page),
              prev: pagination_url(prev_page),
              last: pagination_url(@total_pages),
              first: pagination_url(1)
            }
          end         
      	end
      end
  	end
  end
end