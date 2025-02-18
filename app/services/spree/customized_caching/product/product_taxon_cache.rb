module Spree::CustomizedCaching::Product
	class ProductTaxonCache
		def initialize(ids=nil)
			if ids.nil? || !ids.is_a?(Array)
				@ids = fetch_product_ids_to_cache
			else
				@ids = ids
			end
		end

		def execute
			@ids.each do |id|
				data = serialized_product(id)
				cache_key = generate_cache_key(id)
				if Rails.cache.exist?(cache_key)
					Rails.cache.delete(cache_key)
				end
				Rails.cache.write(cache_key, data, expires_in: 7.days)
			end
		end

		private

		def serialized_product id
			serialize_collection(Spree::Product.where(id: id))
		end

		def fetch_product_ids_to_cache
		  @ids ||= Rails.cache.fetch(scope_cache_key, expires_in: 144.hours) do
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
			::Spree::Api::V3::Storefront::ProductInTaxonSerializer.new(collection).
			serializable_hash
		end


	    def generate_cache_key(id)
	      "pt_#{id}_cache"
	    end	
	end
end