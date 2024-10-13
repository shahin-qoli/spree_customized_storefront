Spree::Core::Engine.add_routes do
  namespace :api, defaults: { format: 'json' } do
    namespace :v2 do
      namespace :storefront do
        resources :products, only: %i[index show] do
          collection do
            get "search"
          end
        end
      end  
    end    
  end
end
