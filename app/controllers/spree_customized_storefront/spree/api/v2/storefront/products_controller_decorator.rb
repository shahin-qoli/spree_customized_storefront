
module SpreeCustomizedStorefront::Spree
  module Api
    module V2
      module Storefront
        module ProductsControllerDecorator

          def search
            start_time = Time.now
            @page = params[:page].present? ? params[:page].to_i : 1
            @per_page = params[:per_page].present? ? params[:per_page].to_i : 24
            @sort_by = params[:sort_by]
            base_data = products_data
            step4_time = Time.now
            p "*****STEP4 - Time taken: #{step4_time - start_time} seconds*****"
            meta = collect_meta_data(base_data, @per_page)
            step5_time = Time.now
            p "*****STEP5 - Time taken: #{step5_time - step4_time} seconds*****"
            links = customized_collection_links(@page)
            step6_time = Time.now
            p "*****STEP6 - Time taken: #{step6_time - step5_time} seconds*****"
            base_data[:meta] = meta
            base_data[:links] = links
            render :json => base_data, status: 200
            total_time = Time.now
            p "*****Total Time taken for search: #{total_time - start_time} seconds*****"
          end

          
          

          def products_data
            @products_data ||= fetch_products(customized_collection)
          end
          

def customized_collection
  return @customized_collection if @customized_collection

  @customized_collection, @total_count = customized_collection_finder.new(params: finder_params).execute(@sort_by, @page, @per_page)
  @customized_collection
end


def fetch_products(product_ids)
  start_time = Time.now
  p "*********START*******"
  keys = product_ids.map { |id| "spree_customized_product_#{id}_cache" }
  p keys
  products = Rails.cache.read_multi(*keys)
            step1_time = Time.now
            p "*****STEP1 - Time taken: #{step1_time - start_time} seconds*****"
  missing_ids = product_ids.reject { |id| products["spree_customized_product_#{id}_cache"] }
  unless missing_ids.empty?
    cache_products_service.new(missing_ids).execute
    new_products = Rails.cache.read_multi(*missing_ids.map { |id| "spree_customized_product_#{id}_cache" })
    products.merge!(new_products)
  end
              step2_time = Time.now
            p "*****STEP2 - Time taken: #{step2_time - step1_time} seconds*****"
  integrate_data(products.values.compact)
end


def integrate_data(data)
  return { data: [], included: [] } if data.empty?
  step2_start = Time.now
  merged_data = { data: [], included: [] }
  unique_included = {}

  data.each do |d|
    merged_data[:data].concat(d[:data])

    d[:included].each do |item|
      unique_key = [item[:id], item[:type]]
      unique_included[unique_key] ||= item
    end
  end
            step3_time = Time.now
            p "*****STEP3 - Time taken: #{step3_time - step2_start} seconds*****"
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
