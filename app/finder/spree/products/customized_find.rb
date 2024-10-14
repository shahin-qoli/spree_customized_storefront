module Spree
  module Products
    class CustomizedFind
      def initialize(params:, current_currency: nil)
        @scope = Spree::Taxon.find(10673).products.pluck(:id)

        ActiveSupport::Deprecation.warn('`current_currency` param is deprecated and will be removed in Spree 5') if current_currency

        if current_currency.present?
          ActiveSupport::Deprecation.warn(<<-DEPRECATION, caller)
            `current_currency` param is deprecated and will be removed in Spree 5.
            Please pass `:currency` in `params` hash instead.
          DEPRECATION
        end
        @customized             = params.dig(:filter, :customized)
        @store            = params[:store] || Spree::Store.default        
        @taxons           = params.dig(:filter, :taxons)
        @in_stock         = params.dig(:filter, :in_stock)

        # @ids              = String(params.dig(:filter, :ids)).split(',')
        # @skus             = String(params.dig(:filter, :skus)).split(',')

        # @price            = map_prices(String(params.dig(:filter, :price)).split(','))
        # @currency         = current_currency || params.dig(:filter, :currency) || params[:currency]
        
        # @concat_taxons    = taxon_ids(params.dig(:filter, :concat_taxons))
        # @name             = params.dig(:filter, :name)
        # @options          = params.dig(:filter, :options).try(:to_unsafe_hash)
        # @option_value_ids = params.dig(:filter, :option_value_ids)
        # @sort_by          = params.dig(:sort_by)
        # @deleted          = params.dig(:filter, :show_deleted)
        # @discontinued     = params.dig(:filter, :show_discontinued)
        # @properties       = params.dig(:filter, :properties)
       
        # @backorderable    = params.dig(:filter, :backorderable)
        # @purchasable      = params.dig(:filter, :purchasable)
      end

      def execute
        product_ids = by_customized(scope)
        product_ids = by_taxons(product_ids)
        # products = show_only_stock(products)
        
        # products = by_ids(scope)
        # products = by_skus(products)
        # products = by_price(products)
        # products = by_currency(products)
        
        # products = by_concat_taxons(products)
        # products = by_name(products)
        # products = by_options(products)
        # products = by_option_value_ids(products)
        # products = by_properties(products)
        # products = include_deleted(products)
        # products = include_discontinued(products)
        
        # products = show_only_backorderable(products)
        # products = show_only_purchasable(products)
        # products = ordered(products)

        product_ids.distinct
      end

      private

      attr_reader :ids, :skus, :price, :currency, :taxons, :concat_taxons, :name, :options, :option_value_ids, :scope,
                  :sort_by, :deleted, :discontinued, :properties, :store, :in_stock, :backorderable, :purchasable,:customized
      def customized?
          customized.present?
      end

      def taxons?
        taxons.present?
      end
      
      def by_customized(products)
          return products unless customized?
          Spree::Product.search(customized, match: :word).pluck(:id)  
      end

      def by_taxons(product_ids)
          return product_ids unless taxons?
          Product.search(where: { taxon_ids: taxons, product_id: product_ids }).pluck(:id)  
          #products.joins(:classifications).where(Classification.table_name => { taxon_id: taxons })
      end

    end
  end
end