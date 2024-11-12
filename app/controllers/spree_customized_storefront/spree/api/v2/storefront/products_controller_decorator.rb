
module SpreeCustomizedStorefront::Spree
  module Api
    module V2
      module Storefront
        module ProductsControllerDecorator
          include Spree::Api::V2::Storefront::CustomizedSearchConcerns
          def index
            if params.dig(:filter, :customized).nil? || params.dig(:filter, :customized).empty?
              super
            else
              @page = params[:page].present? ? params[:page].to_i : 1
              @per_page = params[:per_page].present? ? params[:per_page].to_i : 24
              @sort_by = params[:sort_by]
              base_data = products_data
              meta = collect_meta_data(@per_page)
              links = customized_collection_links(@page)
              base_data[:meta] = meta
              base_data[:links] = links
              render :json => base_data, status: 200
            end
          end
        end
      end
    end
  end
end
Spree::Api::V2::Storefront::ProductsController.prepend(SpreeCustomizedStorefront::Spree::Api::V2::Storefront::ProductsControllerDecorator)
