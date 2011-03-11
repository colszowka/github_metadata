# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "github_metadata/version"

Gem::Specification.new do |s|
  s.name        = "github_metadata"
  s.version     = GithubMetadata::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Christoph Olszowka"]
  s.email       = ["christoph at olszowka de"]
  s.homepage    = ""
  s.summary     = %q{Extracts additional information from Github repos that isn't available via API}
  s.description = %q{Extracts additional information like amount of committers, issues and wiki pages from Github repos}

  s.rubyforge_project = "github_metadata"
  
  s.add_dependency 'nokogiri'
  s.add_dependency 'feedzirra'
  s.add_dependency 'i18n'
  s.add_development_dependency 'rspec', '>= 2.0.0'
  s.add_development_dependency 'simplecov', ">= 0.4.1"
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
