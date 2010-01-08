module GeozipAutocomplete
  include GeoKit::Geocoders

  ALL = [:lng, :province, :full_address, :country, :city, :zip,
         :lat, :district, :country_code, :street_address, :state ]

  def self.included(controller)
    controller.send :helper, GeozipAutocompleteHelper
    controller.class_eval do
      def zip_complete
        puts params.inspect
        geo_loc = GoogleGeocoder.do_reverse_geocode(GoogleGeocoder.geocode(params[:zip], :bias => 'br').to_lat_lng)
        geo_hash = geo_loc.zip_complete_hash
        render :update do |page|
          if geo_hash[:street_address]
            m = geo_hash[:street_address].match(/^(.+)[\,$]/)
            geo_hash[:street_address] = m[1] if(m && m[1])
            page.call "zip_#{params[:zip_id]}_autocomplete", geo_hash.to_json
          else
            page.call 'alert', 'address not found'
          end
        end
      end
    end
  end
end