module Spree::Api::V3::Storefront
	class ProductInTaxonSerializer < Spree::Api::V3::BaseSerializer
		include ::Spree::Api::V2::DisplayMoneyHelper
		attributes :id, :h1_title, :name, :display_price
		attributes :name, :available_on, :h1_title, :meta_description, :meta_keywords,:public_metadata
    attribute :purchasable do |product|
      product.purchasable?
    end

    attribute :in_stock do |product|
      product.in_stock?
    end

    attribute :backorderable do |product|
      product.backorderable?
    end

    attribute :available do |product|
      product.available?
    end

    attribute :price do |product, params|
      price(product, currency)
    end

    attribute :display_price do |product, params|
      display_price(product, currency)
    end

    attribute :compare_at_price do |product, params|
      compare_at_price(product, currency)
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