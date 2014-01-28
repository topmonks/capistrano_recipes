# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "capistrano_recipes/version"

Gem::Specification.new do |s|
  s.name        = "capistrano_recipes"
  s.version     = CapistranoRecipes::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Marian Mrózek", "Jan Uhlář"]
  s.email       = %w(mrozek.marian@gmail.com jan.uhlar@topmonks.com)
  s.homepage    = "https://github.com/rubydev/capistrano_recipes"
  s.summary     = "Bunch of capistrano recipes"
  s.description = "Some useful recipes for capistrano"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
  s.extra_rdoc_files = %w(LICENSE)

  s.add_dependency "capistrano", ['>= 2.8.0', '< 3.0']
  s.add_development_dependency 'rspec'

end
