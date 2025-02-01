module Spree::Api::V3::Storefront
	class MiarzeController < Spree::Api::V2::BaseController

		def get_products_of_taxon
			if params[:taxon_id].nil? && params[:permalink].nil?
				raise "You MUST provide taxon_id OR permalink"
			end
			key = params[:taxon_id].to_i > 0 ? params[:taxon_id].to_i : params[:permalink].strip
			if key.is_a? Integer
				taxon = Spree::Taxon.find key
			else 
				taxon = Spree::Taxon.find_by(permalink: key)
			end
			if taxon.nil?
				raise "Couldnt find taxon with #{key}"
			else
				@taxon_id = taxon.id
				@all_data_ids = taxon.products.map(&:id)
				@count = @all_data_ids.size
				if params[:sort_by].nil?
					@products = taxon.products.page(params[:page || 1]).per(params[:per_page] || 24)
				else
					@products = sort.page(params[:page || 1]).per(params[:per_page] || 24)
				end
			end

			data = {
				:products => products_in_taxon_serializer.new(@products).serializable_hash[:data].map { |d| d[:attributes] },
				:meta => gather_meta_data
			}
			render :json => data
		rescue StandardError => e
			render :json => {:error => e.message}
		end

		private
		def products_in_taxon_serializer
			Spree::Api::V3::Storefront::ProductInTaxonSerializer
		end
		def keep_unique_paths(paths)
			# Build a trie to track all paths and their subpaths
			trie = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

			# Insert all paths into the trie
			paths.each do |path|
				node = trie
				path.each { |segment| node = node[segment] }
			end

			# Collect paths that end at leaf nodes (no further subpaths)
			paths.select do |path|
				node = trie
				# Traverse the trie to the end of the current path
				path.all? { |segment| node = node[segment] } && node.empty?
			end
		end
		def customized_collect_taxons
            keep_unique_paths(Spree::Product.where(id: @all_data_ids).
            map{|item| item.taxons.reject{|tx| tx.hide_from_nav}}.flatten.uniq.
            map(&:permalink).reject{|item| item.include?("brndh")}.map{|item| item.split("/")}).map{|item| item.join("/")}
        end


		def gather_meta_data

			meta = {
				"count": @products.size,
				"total_count": @products.total_count,
				"total_pages": @products.total_pages,
				"filters":{
					"option_types": customized_collect_option_types,
					"taxons": customized_collect_taxons
				}
			}
		end
		def customized_collect_option_types
			return [] if @all_data_ids.empty?
			brands = get_brands
			[{
			  "id": 1,
			  "name": "brand",
			  "presentation": "برند",
			  "option_values": brands
			}] 
		end	
        def get_brands
	        keys = @all_data_ids.map { |id| "spree_brands_product_#{id}_cache" }
	        brands = Rails.cache.read_multi(*keys)
	        missing_ids = @all_data_ids.reject { |item| brands["spree_brands_product_#{item}_cache"] }
	        unless missing_ids.empty?
	          cache_brands_service.new(missing_ids).execute
	          new_brands = Rails.cache.read_multi(*missing_ids.map { |id| "spree_brands_product_#{id}_cache" })
	          brands.merge!(new_brands)
	        end
	        brands.values.compact.flatten.uniq
        end		

		def cache_brands_service
			Spree::CustomizedCaching::Brand::Cache
		end       

		def sort
			case params[:sort_by]
			when "default"
				sql = <<-SQL
					SELECT spree_products.id
					FROM spree_products
					JOIN spree_products_taxons ON spree_products_taxons.product_id = spree_products.id
					WHERE spree_products_taxons.taxon_id = #{@taxon_id}
					GROUP BY spree_products.id
					ORDER BY 
					MAX(spree_products.in_stock::int) DESC,  -- Ensure in-stock products come first
					MIN(spree_products_taxons.position) ASC
				SQL
				product_ids = ActiveRecord::Base.connection.execute(sql).map { |row| row['id'] }

				ordered_products_relation = Spree::Product
				.select("#{Spree::Product.table_name}.*, 
				   ARRAY_POSITION(ARRAY[#{product_ids.join(',')}]::bigint[], #{Spree::Product.table_name}.id) AS position")
				.where(id: product_ids)
				.order(Arel.sql("in_stock DESC, position"))
       		when 'price'
            	sort_by_price(:desc)
            when "-price"
            	sort_by_price(:asc)
            else
            	Spree::Product.where(id: @all_data_ids)
            end
		end 
		def sort_by_price(order)
			sorted_ids = Spree::Product.search(where:{product_id: @all_data_ids},order: {in_stock: :desc, price: order}, load: false).pluck(:id)
			ordered_products_relation = Spree::Product
			.select("#{Spree::Product.table_name}.*, 
			   ARRAY_POSITION(ARRAY[#{sorted_ids.join(',')}]::bigint[], #{Spree::Product.table_name}.id) AS position")
			.where(id: sorted_ids)
			.order(Arel.sql("in_stock DESC, position"))
		end	
	end
end

