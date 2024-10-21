
module SpreeCustomizedStorefront::Spree
  module Api
    module V2
      module Storefront
        module ProductsControllerDecorator

          def search
            @page = params[:page].present? ? params[:page].to_i : 1
            @per_page = params[:per_page].present? ? params[:per_page].to_i : 24
            @sort_by = params[:sort_by]
            base_data = products_data
            meta = collect_meta_data(base_data, @per_page)
            links = customized_collection_links(@page)
            base_data[:meta] = meta
            base_data[:links] = links
            render :json => base_data, status: 200
          end

          
          

          def products_data
            @products_data ||= fetch_products(customized_collection)
          end
          

          def customized_collection
            customized_collection_data ||= customized_collection_finder.new(params: finder_params).
            execute(@sort_by,@page,@per_page)
            p "afteeeeeeeeeeeeer FFFFFFFFFFFFFFFFFFFFFFFFFFFIND"
            @customized_collection = customized_collection_data[0]
            @total_count = customized_collection_data[1]
            @customized_collection
          end

          def fetch_products(product_ids)
            data = []
            product_ids.each do |id|
              key = "spree_customized_product_#{id}_cache"
              product = Rails.cache.read(key)
              if product.nil?
                cache_products_service.new([id]).execute
                product = Rails.cache.read(key)
              end
              data.push(product)
            end
            integrate_data(data)
          end

def integrate_data(data)
  return { data: [], included: [] } if data.empty?

  base = data.first
  unique_included = {}

  # Start by merging 'data' without considering 'included'
  data[1..].each do |d|
    base[:data] += d[:data]
  end

  # Handle 'included' separately and avoid duplicates
  data.each do |d|
    d[:included].each do |item|
      # Use a tuple (id, type) for uniqueness check
      unique_key = [item[:id], item[:type]]
      unique_included[unique_key] ||= item
    end
  end

  # Assign the unique 'included' items back to the base
  base[:included] = unique_included.values

  base
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

  option_types = {}
  option_values_by_type = Hash.new { |h, k| h[k] = [] }

  # Collect option types and group option values by option_type
  products_data[:included].each do |item|
    case item[:type]
    when :option_type
      # Use a hash to avoid duplicates
      option_types[item[:id]] ||= {
        id: item[:id],
        name: item[:attributes][:name],
        presentation: item[:attributes][:presentation],
        option_values: []
      }
    when :option_value
      option_type_id = item[:relationships][:option_type][:data][:id].to_i
      # Group option values by option_type_id
      option_values_by_type[option_type_id] << {
        id: item[:id],
        name: item[:attributes][:name],
        presentation: item[:attributes][:presentation],
        position: item[:attributes][:position]
      }
    end
  end

  # Assign grouped option values to their respective option types
  option_types.each do |id, option_type|
    option_type[:option_values] = option_values_by_type[id]
  end

  # Return the option types as an array
  option_types.values
end


          def customized_collection_finder
            Spree::Products::CustomizedFind
          end

          def cache_products_service
            Spree::CustomizedCaching::Product::Cache
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
Spree::Api::V2::Storefront::ProductsController.prepend(SpreeCustomizedStorefront::Spree::Api::V2::Storefront::ProductsControllerDecorator)