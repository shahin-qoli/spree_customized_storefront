module Spree
  module Products
    class CustomizedFind
      def initialize(params:, current_currency: nil)
        @scope = Spree::Product.search(
          '*', 
          where: { taxon_ids: [10673] }
        ).pluck(:id)

        ActiveSupport::Deprecation.warn('`current_currency` param is deprecated and will be removed in Spree 5') if current_currency

        if current_currency.present?
          ActiveSupport::Deprecation.warn(<<-DEPRECATION, caller)
            `current_currency` param is deprecated and will be removed in Spree 5.
            Please pass `:currency` in `params` hash instead.
          DEPRECATION
        end
        @customized             = params.dig(:filter, :customized)
        @store            = params[:store] || Spree::Store.default        
        @taxons           = taxon_ids(params.dig(:filter, :taxons))
        @in_stock         = params.dig(:filter, :in_stock)
      end

      def execute(sort_by,page,per_page)
        product_ids = by_customized(scope)
        product_ids = by_taxons(product_ids)
        product_ids = order_paginate(product_ids,sort_by,page,per_page)

        product_ids
      end

      private

      attr_reader :ids, :skus, :price, :currency, :taxons, :concat_taxons, :name, :options, :option_value_ids, :scope,
                  :sort_by, :deleted, :discontinued, :properties, :store, :in_stock, :backorderable, :purchasable,:customized
      def customized?
          customized.present?
      end

      def taxons?
        p "haaaaaaaaaaadasasssssss"
        p taxons
        taxons.present?
      end
      
      def by_customized(products)
          return products unless customized?
          Spree::Product.search(customized, 
                      match: :word, 
                      where: { product_id: products }
          ).pluck(:id)
          # Spree::Product.search(customized, match: :word).pluck(:id)  
      end

      def by_taxons(product_ids)
          return product_ids unless taxons?
          return product_ids if taxons[0].to_i == "10673".to_i
          Spree::Product.search("*", 
                      match: :word, 
                      where: { product_id: product_ids, taxon_ids: taxons }
          ).pluck(:id)
          #products.joins(:classifications).where(Classification.table_name => { taxon_id: taxons })
      end
      def taxon_ids(taxons_ids)
        return if taxons_ids.nil? || taxons_ids.to_s.blank?

        taxons_ids.to_s.split(',')
      end

      def order_paginate(product_ids, sort_by = nil, page = 1, per_page = 24)
        sort_option = case sort_by
                      when 'price-high-low'
                        { price: :desc }
                      when 'price-low-high'
                        { price: :asc }
                      when 'create-date'
                        { created_at: :desc }
                      else
                        { _score: :desc } # Default: sort by relevance score
                      end

        # Calculate the offset for pagination
        offset = (page - 1) * per_page

        # Perform the search with sorting and pagination
        Spree::Product.search(
          where: { product_id: product_ids },    # Filter by product_ids
          order: sort_option,            # Apply sorting based on sort_by
          limit: per_page,               # Number of products per page
          offset: offset                 # Start from this position (for pagination)
        )
      end  

    end
  end
end