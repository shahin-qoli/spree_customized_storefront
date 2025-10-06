module Spree
  module Api
    module V3
      module Storefront
        class VersionController < ApplicationController
          # Disable CSRF and enforce XML format
          protect_from_forgery with: :null_session

          def backend_version
            version_file = Rails.root.join('spree_customized_storefront', 'version.xml')

            unless File.exist?(version_file)
              return render json: { error: "Version file not found" }, status: :not_found
            end

            xml_content = File.read(version_file)

            # Send as proper XML with UTF-8 encoding
            render xml: xml_content, content_type: 'application/xml; charset=UTF-8'
          rescue => e
            render json: { error: e.message }, status: :bad_request
          end
        end
      end
    end
  end
end
