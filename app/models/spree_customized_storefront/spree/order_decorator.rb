module SpreeCustomizedStorefront::Spree::OrderDecorator
	def self.prepended(base)
		base.scope :without_payment, -> {left_joins(:payments).where(spree_payments: {id:nil}) }
	end
end

Spree::Order.prepend SpreeCustomizedStorefront::Spree::OrderDecorator