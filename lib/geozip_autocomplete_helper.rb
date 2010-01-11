module GeozipAutocompleteHelper

  def zip_field(object_name, method, options = {})
    raise ArgumentError, "Missing address_fields option" unless options[:address_fields]

    remote_function_opts = [:controller, :country_code, :warn_if_invalid].inject({}){ |hash, opt| hash[opt] = options.delete(opt); hash } 
    fields = options.delete :address_fields
    zip_id = ActionView::Helpers::InstanceTag.text_field_id(object_name, method, options)
    options[:onblur] = remote_zip_complete_function(zip_id, remote_function_opts)
    script_zip_complete(zip_id, fields) +
    text_field(object_name, method, options)
  end

  def script_zip_complete(zip_id, fields)
    function = "function zip_#{zip_id}_autocomplete(json_fields) {"
    function << 'var fields = json_fields.evalJSON(true);'
    fields.each do |field, name|
      raise ArgumentError, "invalid address field" unless GeozipAutocomplete::ALL.include?(field)
      function << "$(\"#{name}\").value = fields.#{field};"
    end
    function << '}'

    javascript_tag function
  end

  def remote_zip_complete_function(zip_id, options = {})
    country_code = options.delete(:country_code) || GeozipAutocomplete::DEFAULT_COUNTRY_CODE
    opts = { :url  => { :action => :zip_complete, :zip_id => zip_id, :warn_if_invalid => options.delete(:warn_if_invalid)} }
    if GeozipAutocomplete::ZIP_FORMAT.keys.include? country_code
      opts[:with] = "'zip=' + $(\"#{zip_id}\").value + '&country_code=#{country_code}'"
    else
      opts[:with] = "'zip=' + $(\"#{zip_id}\").value + '&country_code=' + $(\"#{country_code}\").value"
    end

    opts[:url].update(:controller => controller) if options[:controller]
    remote_function opts
  end

  def link_to_zip_complete_refresh(name, zip_id, options = {}, html_options = {})
    link_to_function name, remote_zip_complete_function(zip_id, options), html_options
  end

  def button_to_zip_complete_refresh(name, zip_id, options = {}, html_options = {})
    button_to_function name, remote_zip_complete_function(zip_id, options), html_options
  end
end                          