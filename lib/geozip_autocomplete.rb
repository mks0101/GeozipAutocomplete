module GeozipAutocomplete
  include GeoKit::Geocoders

  ALL = [:lng, :province, :full_address, :country, :city, :zip,
         :lat, :district, :country_code, :street_address, :state ]

  DEFAULT_COUNTRY_CODE = :us

  config_path = File.expand_path('../config', File.dirname(__FILE__))
  ZIP_FORMAT = YAML.load(File.open File.join(config_path, 'zip_format.yml')).inject({}) do |hash, (k, v)|
    hash[k.to_sym] = Regexp.new v
    hash
  end

  COUNTRY_NAMES = YAML.load(File.open File.join(config_path, 'countries.yml')).inject({}) do |hash, (key, value)|
    value.each{ |v| hash[v.to_sym] = key.to_sym }
    hash
  end

  def self.included(controller)
    controller.send :helper, GeozipAutocompleteHelper
  end

  def zip_complete
    normalize_country_code
    begin
      invalid_zip_format_error and return if invalid_zip_format?(params[:zip], params[:country_code])
      geocode = GoogleGeocoder.geocode("#{params[:zip]}, #{params[:country_code]}", :bias => params[:country_code])
      in_country_geocode = geocode.all.find{ |g| g.country_code.downcase.to_sym == params[:country_code] }
      geo_loc = GoogleGeocoder.do_reverse_geocode(in_country_geocode.to_lat_lng)
      geo_hash = geo_loc.zip_complete_hash
      render :update do |page|
        page.call "zip_#{params[:zip_id]}_autocomplete", geo_hash.to_json
      end
    rescue
      not_found_zip_error
    end
  end

  private

  def invalid_zip_format_error
    if params[:warn_if_invalid]
      render(:update){ |page| page.call 'alert', 'Zip format not valid' }
    else
      render :nothing => true
    end
  end

  def not_found_zip_error
    render(:update){ |page| page.call 'alert', 'Address could not be found' }
  end

  def normalize_country_code
    if params[:country_code].nil?
      params[:country_code] = DEFAULT_COUNTRY_CODE
    else
      country_code = params[:country_code].downcase.to_sym
      params[:country_code] = COUNTRY_NAMES[country_code] || (country_code if ZIP_FORMAT.keys.include?(country_code))
    end
  end

  def invalid_zip_format?(zip, country_code)
    zip.match(ZIP_FORMAT[country_code]).nil?
  end
end