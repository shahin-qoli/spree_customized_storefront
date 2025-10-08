module Spree::Api::V3::Storefront
	class ProductInTaxonSerializer < Spree::Api::V3::BaseSerializer
		include ::Spree::Api::V2::DisplayMoneyHelper
    attribute :_productId do |product|
      product.id
    end

    attribute :metaDescription  do |product|
      product.meta_description
    end
    attribute :metaTitle  do |product|
      product.meta_title
    end
    attribute :metaKeywords do |product|
      product.meta_keywords
    end
		attributes :h1_title, :name
		attributes :name, :available_on, :h1_title,:public_metadata
    attribute :purchasable do |product|
      product.purchasable?
    end

    attribute :inStock do |product|
      product.in_stock? && product.available?
    end

    attribute :backorderable do |product|
      product.backorderable?
    end

    attribute :available do |product|
      product.in_stock? && product.available?
    end

    attribute :price do |product|
      {
        current: price(product, currency),
        original: compare_at_price(product, currency)
      }
    end

    attribute :displayPrice do |product, params|
      display_price(product, currency)
    end


    attribute :display_compare_at_price do |product, params|
      display_compare_at_price(product, currency)
    end
		attribute :images do |product|
      if product.variant_images.first.nil?
        []
      else
        img = product.variant_images.first
        [{
          "id": img.id,
          "alt": img.alt,
          "styles": [
          {
           "height": 240,
           "width": 240,
           "url": img.generate_url(size: image_size) 
          }
                    ]
                  }]			     
      end
		end   

		private
		def self.currency
			"IRR"
		end

    def self.image_size
      "240x240"
    end
	end
end