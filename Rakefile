require 'rubygems'
require 'rake'
require 'bundler'
begin
  Bundler.setup(:default, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "paypal-permissions"
  gem.homepage = "http://github.com/isaachall/paypal-permissions"
  gem.license = "MIT"
  gem.summary = %Q{Ruby implementation of the PayPal Permissions API.}
  gem.description = %Q{Ruby implementation of the PayPal Permissions API.}
  gem.email = "isaac@isaachall.com"
  gem.authors = ["Isaac Hall"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "paypal-permissions #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
