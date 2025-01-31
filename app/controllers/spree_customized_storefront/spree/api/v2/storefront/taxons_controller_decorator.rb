
module SpreeCustomizedStorefront::Spree
  module Api
    module V2
      module Storefront
        module TaxonsControllerDecorator

          def miarze_taxons_tree
            all_taxons = Spree::Taxon.all
            taxons = build_taxon_tree(all_taxons)
            render :json => taxons
          end

          def build_taxon_tree(taxons, parent_id = nil)
            # Select taxons that belong to the current parent
            children = taxons.select { |taxon| taxon.parent_id == parent_id }

            # Return an empty array if no children are found
            return [] if children.empty?

            # Recursively build the tree for each child
            children.map do |taxon|
              {
                id: taxon.id,
                name: taxon.name,
                permalink: taxon.permalink, # Add permalink to the hash
                children: build_taxon_tree(taxons, taxon.id) # Recursively build children
              }
            end
          end          
        end
      end
    end
  end
end

Spree::Api::V2::Storefront::TaxonsController.prepend(SpreeCustomizedStorefront::Spree::Api::V2::Storefront::TaxonsControllerDecorator)
