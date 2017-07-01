$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "dynamic_paperclip/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dynamic_paperclip"
  s.version     = DynamicPaperclip::VERSION
  s.author      = 'Jim Ryan'
  s.email       = ["jim@room118solutions.com"]
  s.homepage    = "http://github.com/room118solutions/dynamic_paperclip"
  s.summary     = "Generate Paperclip attachment styles on the fly"
  s.description = "Let's your views define attachment styles, and delays processing all the way to the first user who requests it."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'rack'
  s.add_dependency "paperclip", ">= 3.5.1"
  s.add_dependency 'activesupport'

  # Required for ActionDispatch::Response::FileBody
  s.add_dependency "actionpack", ">= 5.0"

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'mocha'
  s.add_development_dependency "rails", "~> 5.0.2"
  s.add_development_dependency 'appraisal'
end
