
module SpreeCustomizedStorefront::Spree
  module Api
    module V2
      module Storefront
        module ProductsControllerDecorator

          def search
            page = params[:page].present? ? params[:page].to_i : 1
            per_page = params[:per_page].present? ? params[:per_page].to_i : 24
            fetch_products(customized_collection)
          end

          private

          def customized_collection
            @customized_collection ||= if defined?(customized_collection_finder)
                              customized_collection_finder.new(scope: scope, params: finder_params).execute
                            else
                              scope
                            end
          end

          def customized_collection_finder
            Spree::Product::CustomizedFind
          end
        end
      end
    end
  end
end
Spree::Api::V2::Storefront::ProductsController.prepend(SpreeCustomizedStorefront::Spree::Api::V2::Storefront::ProductsControllerDecorator)

module Spree
  module Api
    module V2
      module Storefront
        class ProductsController < ::Spree::Api::V2::ResourceController
          def index
            # Get the pagination parameters
            page = params[:page].present? ? params[:page].to_i : 1
            per_page = params[:per_page].present? ? params[:per_page].to_i : 24

            cache_key = generate_cache_key(page, per_page) # Include page in cache key

            # Fetch from cache or create the desired response object
            response = Rails.cache.fetch(cache_key, expires_in: 12.hours) do
              products = fetch_products # Fetch products manually without ActiveRecord includes

              # Use Kaminari.paginate_array to paginate non-ActiveRecord arrays
              paginated_products = Kaminari.paginate_array(products).page(page).per(per_page)
              
              build_json_response(paginated_products, page, per_page, products.size) # Pass total size for meta info
            end

            render json: response
          end

          private

          # Fetch and return products manually (adjust to avoid ActiveRecord's automatic includes)
          def fetch_products
            Spree::Product
              .where(id: filtered_product_ids) # Apply your filter logic here
              .select(:id, :name, :slug, :sku, :compare_at_price, :primary_variant_id, :default_variant_id, :private_metadata)
              .to_a # Convert to array to avoid ActiveRecord's Relation if needed
          end

          # Method to build paginated JSON response with pagination metadata
          def build_json_response(products, current_page, per_page, total_count)
            total_pages = (total_count.to_f / per_page).ceil

            {
              data: products.map do |product|
                {
                  id: product.id.to_s,
                  type: "product",
                  attributes: {
                    name: product.name,
                    slug: product.slug,
                    sku: product.sku,
                    compare_at_price: product.compare_at_price.to_s,
                    private_metadata: product.private_metadata,
                  },
                  relationships: {
                    primary_variant: {
                      data: { id: product.primary_variant_id.to_s, type: "variant" }
                    },
                    default_variant: {
                      data: { id: product.default_variant_id.to_s, type: "variant" }
                    },
                    variants: {
                      data: fetch_variant_relationships(product)
                    },
                    option_types: {
                      data: fetch_option_types(product)
                    },
                    taxons: {
                      data: fetch_taxons(product)
                    }
                  }
                }
              end,
              included: fetch_included_data(products),
              meta: {
                count: products.size,
                total_count: total_count,
                total_pages: total_pages,
                current_page: current_page,
                per_page: per_page
              },
              links: {
                self: pagination_link(current_page, per_page),
                first: pagination_link(1, per_page),
                last: pagination_link(total_pages, per_page),
                next: pagination_link([current_page + 1, total_pages].min, per_page),
                prev: pagination_link([current_page - 1, 1].max, per_page)
              }
            }
          end

          # Create the pagination links based on the current page and per_page
          def pagination_link(page, per_page)
            request.base_url + request.path + "?page=#{page}&per_page=#{per_page}" + additional_params
          end

          # Capture additional query params to include in pagination links
          def additional_params
            params.except(:page, :per_page).to_query.presence ? "&" + params.except(:page, :per_page).to_query : ""
          end

          # Create a unique cache key that includes the page and per_page
          def generate_cache_key(page, per_page)
            "#{params.to_h.sort.to_s}-page-#{page}-per_page-#{per_page}"
          end
        end
      end
    end
  end
end
