module SpreeCustomizedStorefront::Spree::Orders::FindCurrentDecorator


	private

	def incomplete_orders
		Spree::Order.incomplete.not_canceled.without_payment
	end
end

Spree::Orders::FindCurrent.prepend SpreeCustomizedStorefront::Spree::Orders::FindCurrentDecorator