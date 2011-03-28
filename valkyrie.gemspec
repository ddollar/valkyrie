$:.unshift File.expand_path("../lib", __FILE__)
require "valkyrie/version"

Gem::Specification.new do |gem|
  gem.name    = "valkyrie"
  gem.version = Valkyrie::VERSION

  gem.author      = "Valkyrie"
  gem.email       = "ddollar@gmail.com"
  gem.homepage    = "http://github.com/ddollar/valkyrie"
  gem.summary     = "Transfer data between databases with ease."
  gem.description = ""
  gem.executables = "valkyrie"

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 2.5.0"

  gem.add_development_dependency "mysql"
  gem.add_development_dependency "pg"
  gem.add_development_dependency "sqlite3"

  gem.add_dependency "sequel",      "~> 3.20.0"
  gem.add_dependency "rest-client", "~> 1.6.1"
end
