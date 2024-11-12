module Spree
  module Products
    class CustomizedFind
      def initialize(params:, current_currency: nil)
        @scope ||= Rails.cache.fetch(scope_cache_key, expires_in: 24.hours) do
          Spree::Taxonomy.first.taxons.map{|item| item.products.map{|item| item.id}}.flatten!.uniq!
        end
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
        @price            = map_prices(String(params.dig(:filter, :price)).split(','))
        @in_stock         = params.dig(:filter, :in_stock)
        @option_value_ids = params.dig(:filter, :option_value_ids)
      end

      def execute(sort_by)
        product_ids = by_customized(scope)
        product_ids = by_taxons(product_ids)
        product_ids = by_price(product_ids)
        product_ids = show_only_stock(product_ids)
        product_ids = by_option_value_ids(product_ids)
        product_ids = order_paginate(product_ids,sort_by)
        product_ids
      end

      private

      attr_reader :ids, :skus, :price, :currency, :taxons, :concat_taxons, :name, :options, :option_value_ids, :scope,
                  :sort_by, :deleted, :discontinued, :properties, :store, :in_stock, :backorderable, :purchasable,:customized
      def customized?
          customized.present?
      end
      def option_value_ids?
        option_value_ids.present?
      end     
      def taxons?
        taxons.present?
      end
      def price?
        price.present?
      end  
      def by_option_value_ids(product_ids)
         return product_ids unless option_value_ids?
          Spree::Product.search("*", 
                      where: { product_id: product_ids, options_value_ids: option_value_ids },
                      operator: "or"
          ).map(&:id)         
      end   
      def by_customized(products)
          return products unless customized?
          Spree::Product.search(customized, 
                      match: :word, 
                      where: { product_id: products }
          ).map(&:id)
          # Spree::Product.search(customized, match: :word).pluck(:id)  
      end
      def show_only_stock(products)
        return products unless in_stock.to_s == 'true'

        Spree::Product.search("*", 
                      where: { product_id: products, in_stock: in_stock }
          ).map(&:id)
      end
      def by_price(products)
        return products unless price?

        Spree::Product.search("*", 
                      where: { product_id: products, price: { gte: price.min, lte: price.max }}
          ).map(&:id)
      end
      def by_taxons(product_ids)
          return product_ids unless taxons?
          return product_ids if taxons[0].to_i == "10673".to_i
          Spree::Product.search("*", 
                      where: { product_id: product_ids, taxon_ids: taxons }
          ).map(&:id)
          #products.joins(:classifications).where(Classification.table_name => { taxon_id: taxons })
      end
      def taxon_ids(taxons_ids)
        return if taxons_ids.nil? || taxons_ids.to_s.blank?

        taxons_ids.to_s.split(',')
      end

      def order_paginate(product_ids, sort_by = nil)
        sort_option = case sort_by
                      when 'price-high-low'
                        {in_stock: :desc, price: :desc }
                      when 'price-low-high'
                        { in_stock: :desc, price: :asc }
                      when 'create-date'
                        {in_stock: :desc, created_at: :desc }
                      else
                        {in_stock: :desc, _score: :desc } # Default: sort by relevance score
                      end

        # Calculate the offset for pagination
        
        # Perform the search with sorting and pagination
        # Spree::Product.search(
        #   where: { product_id: product_ids },    # Filter by product_ids
        #   order: sort_option,            # Apply sorting based on sort_by
        #   limit: per_page,               # Number of products per page
        #   offset: offset                 # Start from this position (for pagination)
        # )
        Spree::Product.search(
          where: { product_id: product_ids },  
          order: sort_option
        ).map(&:id)
      end  

      def scope_cache_key
        "miarze_product_ids"
      end
      def map_prices(prices)
        prices.map do |price|
          price == 'Infinity' ? Float::INFINITY : price.to_f
        end
      end
    end
  end
end