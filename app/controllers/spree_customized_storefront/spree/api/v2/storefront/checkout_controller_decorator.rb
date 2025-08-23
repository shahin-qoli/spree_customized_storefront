
module SpreeCustomizedStorefront::Spree
  module Api
    module V2
      module Storefront
        module CheckoutControllerDecorator
          def next
            spree_authorize! :update, spree_current_order, order_token
            removed_lines = []
            if spree_current_order.state.eql?("address")
              spree_current_order.line_items.select do |item|
                !item.variant || item.variant.discontinued? || item.insufficient_stock?
              end.flatten.each do |line_item| 
                removed_lines << {
                   id: line_item.id,
                  variant_id: line_item.variant_id,
                  quantity: line_item.quantity,
                  name: line_item.variant.name,
                  descriptive_name: line_item.variant.descriptive_name               
                } 
                remove_line_item_service.call(
                order: spree_current_order,
                line_item: line_item
                )
              end
            end  
            @removed_lines = removed_lines # store it in ivar
            result = next_service.call(order: spree_current_order)
            render_order(result)
          end
def render_order(result)
  if result.success?
    render_serialized_payload do
      payload = serialized_current_order
      payload[:meta] ||= {}
      payload[:meta][:removed_lines] = @removed_lines if defined?(@removed_lines) && @removed_lines.present?
      payload
    end
  else
    render_error_payload(result.error&.value || result.value)
  end
end


          def remove_line_item_service
            Spree::Api::Dependencies.storefront_cart_remove_line_item_service.constantize
          end          
        end
      end
    end
  end
end          
Spree::Api::V2::Storefront::CheckoutController.prepend(SpreeCustomizedStorefront::Spree::Api::V2::Storefront::CheckoutControllerDecorator)
