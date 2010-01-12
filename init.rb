unless defined?(GeoKit)
  puts 'Geokit gem required'
end

class GeoKit::GeoLoc
  def zip_complete_hash
    GeozipAutocomplete::ALL.inject({}) do |hash, field|
      if field == :street_address
        begin
          complete_street_address = self.send field
          m = complete_street_address.match /(\,|$)/
          hash[field] = m.pre_match
        rescue
          hash[field] = nil
        end
      else
        hash[field] = self.send field
      end
      hash
    end
  end
end

class ActionView::Helpers::InstanceTag  #:nodoc:
  def self.text_field_id(object_name, method, options = {})
    new(object_name, method, self, options.delete(:object)).send :add_default_name_and_id, options
    options["id"]
  end
end
