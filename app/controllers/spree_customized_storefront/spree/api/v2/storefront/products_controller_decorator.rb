
module SpreeCustomizedStorefront::Spree
  module Api
    module V2
      module Storefront
        module ProductsControllerDecorator

          def search
            page = params[:page].present? ? params[:page].to_i : 1
            per_page = params[:per_page].present? ? params[:per_page].to_i : 24
            base_data = products_data
            meta = collect_meta_data(base_data, per_page)
            links = customized_collection_links(page)
            base_data[:meta] = meta
            base_data[:links] = links
            render :json => base_data, status: 200
          end

          private
          

          def products_data
            @products_data ||= fetch_products(customized_pagination(customized_collection))
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
            if data.size < 1
              return {:data => [],:included => []}
            end
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
            return [] if products_data[:data].size < 1
            opvls = []
            optps = []
            products_data[:included].each do |item|
              if item[:type] == :option_type
                if optps.select{|op| op[:id] == item[:id] }.empty?
                  optps.push(item)
                end
              elsif item[:type] == :option_value
                if opvls.select{|op| op[:id] == item[:id] }.empty?
                  opvls.push(item)
                end
              end
            end
            optps.map do |optp|
               {
                :id => optp[:id],
                :name => optp[:attributes][:name],              
                :presentation => optp[:attributes][:presentation],
                :option_values => opvls.select do |item|
                  item[:relationships][:option_type][:data][:id].to_i == optp[:id].to_i
                end.map do |item| 
                  {id: item[:id], name: item[:attributes][:name], presentation: item[:attributes][:presentation], position: item[:attributes][:position]}
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