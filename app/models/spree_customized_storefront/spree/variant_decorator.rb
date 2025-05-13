module SpreeCustomizedStorefront::Spree::VariantDecorator
	def self.prepended(base)
		base.after_update_commit :update_in_product_cache
	end

	private

	def update_in_product_cache
		ids = []
		ids.push(self.id)
		Spree::CustomizedCaching::Product::ProductSingleCache.new(ids).execute
	end
end

Spree::Variant.prepend SpreeCustomizedStorefront::Spree::VariantDecorator
