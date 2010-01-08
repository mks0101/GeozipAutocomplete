require File.expand_path(File.join(File.dirname(__FILE__), '../../../../test/test_helper'))

class GeozipAutocompleteTest < Test::Unit::TestCase

  def protect_against_forgery? *args
    false
  end

  def url_for options
    "/addresses/zip_complete?zip_id=address_zip"
  end

  def self.helper *args
    nil
  end

  def params
    {:zip_id => 'some_zip_id', :zip => '09070-010'}
  end

  def render(*args, &block)
    yield(lambda { |x,y| [x, y] })
  end

  GoogleGeocoder = "{\"country\":\"Brasil\",\"lng\":-46.5517649,\"district\":\"Bairro Santa Maria\",\"zip\":\"09070-010\",\"state\":\"SP\",\"street_address\":\"R. Alice Costa\",\"province\":null,\"country_code\":\"BR\",\"lat\":-23.6469295,\"full_address\":\"R. Alice Costa, 276-390 - Bairro Santa Maria, Santo Andr\\u00e9 - SP, 09070-010, Brazil\",\"city\":\"Santo Andr\\u00e9\"}"

  class << GoogleGeocoder
    def method_missing *args
      self
    end
  end

  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::PrototypeHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::CaptureHelper

  include GeozipAutocompleteHelper
  include GeozipAutocomplete

  def test_zip_field
    zip = zip_field(:address, :zip, :address_fields => {:street_address => :address_address, :country => :address_country})
    assert_not_nil zip.match(/zip_address_zip_autocomplete\(json_fields\)/)
    assert_not_nil zip.match(/\$\(\"address_country\"\)\.value\s=\sfields\.country\;/)
    assert_not_nil zip.match(/\$\(\"address_address\"\)\.value\s=\sfields\.street_address\;/)
    assert_not_nil zip.match(/name\=\"address\[zip\]\"/)
    assert_not_nil zip.match(/id\=\"address_zip\"/)
    match = zip.match(/onblur\=\"new\sAjax\.Request\((.+)\)\"/)
    assert_not_nil match
    attrs = match[1].split(/[\,\{\}\s]/)
    assert attrs.include? "'/addresses/zip_complete?zip_id=address_zip'"
    assert attrs.include? 'asynchronous:true'
    assert attrs.include? "parameters:'zip='"
    counter_check zip
    assert_raise ArgumentError do
      zip_field('missing addresses', 'fields hash')
    end
  end

  def test_script_zip_complete
    script = script_zip_complete('some_zip_id', :city => :cidade, :full_address => :endereco_completo)
    assert_not_nil script.match(/zip_some_zip_id_autocomplete\(json_fields\)/)
    counter_check script
    assert_raise ArgumentError do
      script_zip_complete('some_zip_id', :planet => 'mars')
    end
  end

  def test_zip_complete
    javascript_call, json = zip_complete
    assert_equal javascript_call, 'zip_some_zip_id_autocomplete'
    counter_check json
    hash = ActiveSupport::JSON.decode json
    hash.each do |key, value|
      assert GeozipAutocomplete::ALL.include?(key.to_sym)
    end
  end

  def test_remote_zip_complete_function
    zip_function = remote_zip_complete_function 'address_zip'
    match = zip_function.match(/new\sAjax\.Request\((.+)\)$/)
    assert_not_nil match
    attrs = match[1].split(/[\,\{\}\s]/)
    puts zip_function.inspect
    puts attrs.inspect
    assert attrs.include? "'/addresses/zip_complete?zip_id=address_zip'"
    assert attrs.include? 'asynchronous:true'
    assert attrs.include? "parameters:'zip='"
    counter_check zip_function
  end

  def test_refresh_link_and_button
    [ link_to_zip_complete_refresh('Refresh', 'address_zip'),
    button_to_zip_complete_refresh('Refresh', 'address_zip')].each do |link_or_button|
      match = link_or_button.match(/onclick\=\"new\sAjax\.Request\((.+)\).*\;/)
      assert_not_nil match
      attrs = match[1].split(/[\,\{\}\s]/)
      assert attrs.include? "'/addresses/zip_complete?zip_id=address_zip'"
      assert attrs.include? 'asynchronous:true'
      assert attrs.include? "parameters:'zip='"
      counter_check link_or_button
    end
  end

  private

  def counter_check str
    assert_equal str.count('{'), str.count('}')
    assert_equal str.count('['), str.count(']')
    assert_equal str.count('<'), str.count('>')
    assert str.count("'") % 2 == 0
    assert str.count("\"") % 2 == 0
  end
end