module Spree::Api
  module V3
    module Storefront
      class ReviewSerializer < Spree::Api::V3::BaseSerializer
        set_type :review
        attributes :review, :rating, :up_vote,
         :down_vote, :suggest, :created_at, :is_buyer, :title
        attribute :review_conprons do |review|
          Spree::V2::Storefront::ReviewConpronSerializer
          .new(review.review_conprons)
          .serializable_hash[:data]
        end
        attribute :review_images do |review|
          Spree::V2::Storefront::ReviewImageSerializer
          .new(review.review_images)
          .serializable_hash[:data]
        end        
        attribute :user do |review|

          data ||= { is_fake: review.is_fake, la_name: review.la_name, fi_name: review.fi_name }
          data[:is_fake] = review.is_fake
          data[:la_name] = review.la_name
          data[:fi_name] = review.fi_name
          Spree::V2::Storefront::UserReviewSerializer
          .new(review.user,params: data)
          .serializable_hash[:data]
        end               

      end
    end
  end
end