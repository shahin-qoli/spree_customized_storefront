module Spree::Api::V3::Storefront
	class VariantSerializer < Spree::Api::V3::BaseSerializer
		include ::Spree::Api::V2::DisplayMoneyHelper

    attributes :description, :name, :slug, :sku
    attribute :_productId do |variant|
      variant.product.id
    end
    attribute :_variantId do |variant|
      variant.id
    end  
    attribute :available do |variant|
      variant.available?
    end
    attribute :h1_title do |variant|
      variant.product.h1_title
    end
    attribute :metaDescription  do |variant|
      variant.meta_description
    end
    attribute :metaKeywords do |variant|
      variant.meta_keywords
    end

    attribute :optionTypes do |variant|
      variant.product.option_types.map do |opt|
        {
          "id": opt.id,
          "type": "option_type",
          "name": opt.name,
          "position": opt.position,
          "presentation": opt.presentation
        }
      end
    end

    attribute :optionValues do |variant|
      variant.option_values.map do |vlu|
        {
          "id": vlu.id,
        "name": vlu.name,
          "position": vlu.position,
          "presentation": vlu.presentation,
          "optionTypeId": vlu.option_type.id
        }
      end
    end

    attribute :breadcrumbs  do |variant|
      variant.product.generate_breadcrumb
    end

    attribute :properties do |variant|
      variant.product.product_properties.map{|item| {"name": item.property.name, "value": item.value}}
    end

    attribute :displayPrice do |variant, params|
      display_price(variant, currency)
    end
    attribute :price do |variant|
      {
        current: price(variant, currency),
        original: compare_at_price(variant, currency)
      }
    end

    attribute :inStock do |variant|
      variant.in_stock?
    end
    attribute :brand do |variant|
      variant.product.generate_brand

    end
    attribute :product_caution  do |variant|
      variant.product.generate_product_caution
    end
          
    attribute :purchaseLimit  do |variant|
      variant.product.generate_product_purchase_limit
    end

    attribute :ai_review do |variant|
      variant.product.ai_review
    end
    attribute :ai_rating do |variant|
      variant.product.ai_rating
    end

    attribute :images do |variant|
      variant.product.images.map do |item|
        {
          "id": item.id,
          "alt": item.alt,
          "styles":[
            {
              "url": item.generate_url(size: "128x128"),
              "width": "128",
              "height": "128" 
            },
             {
              "url": item.generate_url(size: "600x600"),
              "width": "600",
              "height": "600" 
            },           
          ]
        }
      end
    end
    attribute :review_summary do |variant|
      variant.product.review_summary
    end
    attribute :reviews do |variant|
      variant.product.generate_reviews
    end

    attribute :related_products do |variant, params|
      relation_type = params[:relation_type]

      related = variant.product.generate_related_products(relation_type_id: relation_type)

      {
        productsFromRelation: Spree::V2::Storefront::ProductsCustSerializer
          .new(related[:products_from_relation], params: params)
          .serializable_hash[:data],

        productsFromTaxon: Spree::V2::Storefront::ProductsCustSerializer
          .new(related[:products_from_taxon], params: params)
          .serializable_hash[:data]
      }
    end
    private
    def self.currency
      "IRR"
    end    
  end
end
