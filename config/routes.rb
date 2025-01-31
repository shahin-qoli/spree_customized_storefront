Spree::Core::Engine.add_routes do
  namespace :api, defaults: { format: 'json' } do
    namespace :v2 do
      namespace :storefront do
        resources :taxons do
          collection do
            get "miarze_taxons_tree"
          end
        end
      end  
    end    
  end
end


