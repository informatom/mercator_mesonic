$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mercator_mesonic/version"

Gem::Specification.new do |s|
  s.name        = "mercator_mesonic"
  s.version     = MercatorMesonic::VERSION
  s.authors     = ["Stefan Haslinger"]
  s.email       = ["stefan.haslinger@mittenin.at"]
  s.homepage    = "http://informatom.com"
  s.summary     = "MercatorMesonic provides Mercator ERP Integration for the Mesonic Guided Selling Application."
  s.description = "MercatorMesonic interfaces between Mercator and Mesonic in the realm of customers, addresses, articles, inventories, orders, and orderitems."

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.3"
  s.add_dependency 'activerecord-sqlserver-adapter', '~> 4.0.0'
end
