module GeozipAutocompleteHelper

  def zip_field(object_name, method, options = {})
    raise ArgumentError, "Missing address_fields option" unless options[:address_fields]

    fields = options.delete :address_fields
    zip_id = ActionView::Helpers::InstanceTag.text_field_id(object_name, method, options)
    options[:onblur] = remote_zip_complete_function(zip_id, options.delete(:controller))
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

  def remote_zip_complete_function(zip_id, controller = nil)
    opts = { :url  => { :action => :zip_complete, :zip_id => zip_id },
             :with => "'zip=' + $(\"#{zip_id}\").value" }

    opts[:url].update(:controller => controller) if controller
    remote_function opts
  end

  def link_to_zip_complete_refresh(name, zip_id, controller = nil, html_options = {})
    link_to_function name, remote_zip_complete_function(zip_id, controller), html_options
  end

  def button_to_zip_complete_refresh(name, zip_id, controller = nil, html_options = {})
    button_to_function name, remote_zip_complete_function(zip_id, controller), html_options
  end
end                          