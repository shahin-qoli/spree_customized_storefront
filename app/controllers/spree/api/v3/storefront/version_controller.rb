module Spree::Api::V3::Storefront
	class VersionController < ApplicationController
		def backend_version
			xml_content = File.read(Rails.root.join('spree_customized_storefront','version.xml'))
			render plain: xml_content
		rescue StandardError => e
			render :json => {:error => e.message}, status: 400  	    		
		end
	end
end