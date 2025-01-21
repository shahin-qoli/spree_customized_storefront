module SpreeCustomizedStorefront::Spree::OrderDecorator
	def self.prepend(base)
		base.scope :without_payment, -> {payments.empty?}
	end
end

Spree::Order.prepend SpreeCustomizedStorefront::Spree::OrderDecorator