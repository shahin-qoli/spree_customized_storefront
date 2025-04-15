module SpreeCustomizedStorefront::Spree::ProductDecorator
	def self.prepended(base)
		base.after_update_commit :update_in_product_cache
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
