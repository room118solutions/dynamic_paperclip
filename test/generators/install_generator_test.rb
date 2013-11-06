require 'test_helper'
require 'rails/generators/test_case'
require 'generators/dynamic_paperclip/install_generator.rb'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests DynamicPaperclip::InstallGenerator
  destination File.expand_path("../../tmp", __FILE__)

  setup :prepare_destination

  test 'generates secret and configures DynamicPaperclip to use it' do
    SecureRandom.expects(:urlsafe_base64).with(50).returns('supersecurestring')

    run_generator

    assert_file "config/initializers/dynamic_paperclip.rb", "DynamicPaperclip.config.secret = 'supersecurestring'"
  end
end