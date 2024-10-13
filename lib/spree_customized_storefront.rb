require 'spree_core'
require 'spree_extension'
require 'spree_customized_storefront/engine'
require 'spree_customized_storefront/version'


module SpreeCustomizedStorefront
    class Application < Rails::Application
      config.autoload_paths << Rails.root.join('lib')
      config.paths.add Rails.root.join('lib').to_s, eager_load: true
    end
end