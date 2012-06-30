require 'test/unit'
require 'rubygems'
require "bundler"
require 'yaml'
require 'vcr'
Bundler.setup

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"
require 'paypal/permissions'

module SpecHelper
  # add helper methods here
end

RSpec.configure do |config|
  config.include SpecHelper
  config.extend VCR::RSpec::Macros
  config.mock_with :rspec

  config.before(:all) do
    credentials = YAML.load(File.read(File.join(File.dirname(__FILE__), 'sandbox_credentials.yml')))
    @paypal = Paypal::Permissions::Paypal.new(
      credentials['userid'], credentials['password'],credentials['signature'],credentials['application_id'],credentials['mode']
    )
  end
end

VCR.config do |c|
  c.cassette_library_dir = 'spec/vcr'
  c.stub_with :webmock

  # Uncomment to allow VCR to record new cassettes
  #c.default_cassette_options = { :record => :new_episodes }
end
