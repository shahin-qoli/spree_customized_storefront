module Spree::CustomizedCaching::Product
	class ProductSingleCache
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
			serialize_collection(Spree::Variant.where(id: id))
		end

		def fetch_product_ids_to_cache
			@ids ||= Rails.cache.fetch(scope_cache_key, expires_in: 144.hours) do
				Spree::Taxonomy.first.taxons.map{|txn| txn.products.map{|item| item.variants.map(&:id)}}.flatten!.uniq!
			end
		end

	    def scope_cache_key
	      "miarze_product_ids"
	    end


		def serialize_collection(collection)
			::Spree::Api::V3::Storefront::VariantSerializer.new(collection).
			serializable_hash
		end


	    def generate_cache_key(id)
	    	Digest::MD5::hexdigest("vi_#{id.to_s}_cache")
	    end	
	end
end