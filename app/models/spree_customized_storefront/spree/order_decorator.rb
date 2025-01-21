module SpreeCustomizedStorefront::Spree::OrderDecorator
	def self.prepended(base)
		base.scope :without_payment, -> {payments.empty?}
	end
end

Spree::Order.prepend SpreeCustomizedStorefront::Spree::OrderDecorator