
module SpreeCustomizedStorefront::Spree
  module Api
    module V2
      module Storefront
        module ProductsControllerDecorator

          def search
            page = params[:page].present? ? params[:page].to_i : 1
            per_page = params[:per_page].present? ? params[:per_page].to_i : 24
            products_data = fetch_products(customized_collection)
            meta = collect_meta_data(products_data, per_page)
            p "ALLLLLLLLLLLLLAAAAAAAAAAAh"
            p @total_pages
            links = customized_collection_links(page,@total_pages)
            products_data[:meta] = meta
            products_data[:links] = links
            render :json => products_data, status: 200
          end

          private

          def customized_collection
            @customized_collection ||= customized_collection_finder.new(params: finder_params).execute
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
            base = data.first
            data.each_with_index do |d, i|
              next if i == 0
              base = base.merge(d) do |key,old_value,new_value|
                old_value + new_value
              end
            end
            base
          end

          def collect_meta_data(products_data, per_page)
              count = products_data[:data].size < per_page ? products_data[:data].size : per_page 
              total_count = products_data[:data].size
              @total_pages = (total_count / per_page).to_i
              option_types = customized_collect_option_types(products_data)
              {
                :count => count,
                :total_count => total_count,
                :total_pages => @total_pages,
                :filters => {
                  :option_types => option_types,
                  :product_properties => []
                }
              }
          end          

          def customized_collect_option_types(products_data)
            option_type_ids = products_data[:included].select{ |item| item[:type] == :option_type}.map(:id)
            Spree::OptionType.where(id: option_type_ids).map do |ot|
              {
                :id => ot.id,
                :name => ot.name,              
                :presentation => ot.presentation,
                :option_values => ot.option_values.map do |item| 
                  {id: item.id, name: item.name, presentation: item.presentation, position: item.position}
                end
              }
            end
          end

          def customized_collection_finder
            Spree::Products::CustomizedFind
          end

          def cache_products_service
            Spree::CustomizedCaching::Product::Cache
          end

          def customized_collection_links(current_page,total_pages)
            next_page = current_page < total_pages ? current_page + 1 : total_pages
            prev_page = current_page > 1 ? current_page - 1 : current_page
            {
              self: request.original_url,
              next: pagination_url(next_page),
              prev: pagination_url(prev_page),
              last: pagination_url(total_pages),
              first: pagination_url(1)
            }
          end
        end
      end
    end
  end
end
Spree::Api::V2::Storefront::ProductsController.prepend(SpreeCustomizedStorefront::Spree::Api::V2::Storefront::ProductsControllerDecorator)