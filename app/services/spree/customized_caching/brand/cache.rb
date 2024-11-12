module Spree::CustomizedCaching::Brand
	class Cache

		def initialize(ids=nil)
			if ids.nil? || !ids.is_a?(Array)
				@ids = fetch_product_ids_to_cache
			else
				@ids = ids
			end
		end


		def execute
			@ids.each do |id|
				data = Spree::Product.find(id.to_i).variants.map do |var|
					var.option_values.where(option_type_id: 1).map do |ov|
						{
	            "id": ov.id,
	            "name": ov.name,
	            "presentation": ov.presentation,
	            "position": ov.position					
						}
					end
				end.flatten.uniq
				cache_key = generate_cache_key(id)
				if Rails.cache.exist?(cache_key)
					Rails.cache.delete(cache_key)
				end
				Rails.cache.write(cache_key, data, expires_in: 10.days)
			end
		end

		private

		def serialized_product id
			serialize_collection(Spree::Product.where(id: id))
		end

		def fetch_product_ids_to_cache
		  @ids ||= Rails.cache.fetch(scope_cache_key, expires_in: 24.hours) do
        Spree::Taxonomy.first.taxons.map{|item| item.products.map{|item| item.id}}.flatten!.uniq!
      end
		end

    def scope_cache_key
      "miarze_product_ids"
    end

		def spree_product_serializer
			Spree::V2::Storefront::ProductSerializer
		end

		def miarze_shop_taxon_id
			ENV["MIARZETAXONID"].nil? ? "10673".to_i : ENV["MIARZETAXONID"].to_i
		end

		def serialize_collection(collection)
			::Spree::V2::Storefront::ProductSerializer.new(
				collection,
				collection_options.merge(params: serializer_params)
			).serializable_hash
		end

    def serializer_params
      {
        currency: "IRR",
        locale: "fa",
        price_options: {:tax_zone=>nil},
        store: Spree::Store.find(1),
        user: nil,
        image_transformation: nil,
        taxon_image_transformation: nil
      }
    end

    def collection_options
	    {
	      links: nil,
	      meta: nil,
	      include: [:primary_variant,:default_variant,:"variants.option_values",:option_types,:taxons,:images],
	      fields: {:product=>
	      				[
	      					 :name,
								   :slug,
								   :h1_title,
								   :sku,
								   :compare_at_price,
								   :primary_variant,
								   :default_variant,
								   :variants,
								   :option_types,
								   :taxons,
								   :private_metadata
								],
								 :variant=>
								  [:sku,
								   :price,
								   :display_price,
								   :in_stock,
								   :product,
								   :compare_at_price,
								   :images,
								   :option_values,
								   :is_master]} 
		  }
    end
    def generate_cache_key(id)
      "spree_brands_product_#{id}_cache"
    end
	end
end
