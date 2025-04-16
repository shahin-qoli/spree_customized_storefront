module SpreeCustomizedStorefront::Spree::ProductDecorator
	def self.prepended(base)
		base.after_update_commit :update_in_product_cache
	end

	def generate_breadcrumb
	  data = []
	  ex_perms = ["provider-miarze", "provider-miarze/main"]

	  if !main_taxon.nil?
	    current = main_taxon

	    while !current.nil?
	      if ex_perms.include?(current.permalink)
	        current = current.parent
	        next
	      else
	        begin
	          parsed_meta = JSON.parse(current.meta_description.to_s)
	          ext_data = parsed_meta.is_a?(Hash) ? parsed_meta : {}
	          data.push(
	            {
	              "text": current.name,
	              "link": "/category/#{current.permalink}",
	              "data": ext_data
	            }
	          )
	        rescue JSON::ParserError, TypeError
	          data.push(
	            {
	              "text": current.name,
	              "link": "/category/#{current.permalink}",
	              "data": {}
	            }
	          )
	        end
	      end

	      current = current.parent
	    end
	  end

	  data.push({ "text": "فروشگاه اينترنتي مي ارزه", "link": "/" })
	  data.reverse
	end

	def generate_brand
		brand_taxons = taxons.select{|item| item.permalink.include?("brndh")}
		case brand_taxons.size
		when 1
		brand_taxon = brand_taxons.last
		when 0 
		brand_taxon = nil
		else
		brand_taxon = brand_taxons.max_by { |t| t.permalink.to_s.size }
		end

		if brand_taxon.nil?
			nil
		else
			img = brand_taxon.icon
			brand_image = if img.nil?
				nil
			else
				{
				"styles": [
				  {
				"url": img.generate_url(size: "32x32"),
				"width": "32",
				"height": "32"                
				  },
				  {
				"url": img.generate_url(size: "128x128"),
				"width": "128",
				"height": "128"                
				  }
				],
				"alt": img.alt ,
				"original_url": img.original_url
				}
			end
			taxon = {
			"name": brand_taxon.name,
			"pretty_name": brand_taxon.pretty_name,
			"permalink": brand_taxon.permalink,
			"seo_title": brand_taxon.seo_title,
			"description": brand_taxon.description,
			"meta_title": brand_taxon.meta_title,
			"meta_description": brand_taxon.meta_description,
			"meta_keywords": brand_taxon.meta_keywords,
			"left": brand_taxon.left,
			"right": brand_taxon.right,
			"position": brand_taxon.position,
			"depth": brand_taxon.depth,
			"updated_at": brand_taxon.updated_at,
			"public_metadata": brand_taxon.public_metadata
			}
			{"brand": {
			"brand_image": brand_image,
			"taxon": brand_taxon
			}}
		end
	end

	def generate_product_caution
      if private_metadata.nil?
        nil
      elsif private_metadata.has_key?("caution")
        private_metadata["caution"]
      else
        nil
      end		
	end

	def generate_product_purchase_limit
      if private_metadata.nil?
        nil
      elsif private_metadata.has_key?("limit")
        private_metadata["limit"]
      else
        nil
      end		
	end	

	def generate_related_products(relation_type_id: nil)
	  # Always fetch products from deepest taxon
	  lngst_taxon = taxons.sort_by(&:depth).last
	  i = 0
	  taxon_products = lngst_taxon.products.sample(25).select do |item|
	    if item.in_stock? && item.available?
	      i += 1
	      i <= 10
	    else
	      false
	    end
	  end
	  products_from_taxon = Spree::Product.where(id: taxon_products.map(&:id))

	  # Handle relation-based products only if relation_type is provided
	  products_from_relation = []
	  if relation_type_id.present?
	    relation_type = Spree::RelationType.find_by(id: relation_type_id)
	    if relation_type
	      related_ids = relations.where(relation_type_id: relation_type.id)
	                             .pluck(:related_to_id)
	      products_from_relation = Spree::Product.where(id: related_ids)
	    end
	  else
	      related_ids = relations.pluck(:related_to_id)
	      products_from_relation = Spree::Product.where(id: related_ids)
	  end	  	

	  {
	    products_from_relation: products_from_relation,
	    products_from_taxon: products_from_taxon
	  }
	end
	def generate_reviews
      ::Spree::Api::V3::Storefront::ReviewSerializer.new(
        reviews
      ).serializable_hash[:data]
	end
	private

	def update_in_product_cache
		ids = []
		ids.push(self.id)
		Spree::CustomizedCaching::Product::Cache.new(ids).execute
		Spree::CustomizedCaching::Product::ProductTaxonCache.new(ids).execute
	end
end

Spree::Product.prepend SpreeCustomizedStorefront::Spree::ProductDecorator
