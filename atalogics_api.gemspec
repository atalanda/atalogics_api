# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'atalogics_api/version'

Gem::Specification.new do |spec|
  spec.name          = "atalogics_api"
  spec.version       = AtalogicsApi::VERSION
  spec.authors       = ["Hubert Hoelzl"]
  spec.email         = ["hubert.hoelzl@atalanda.com"]

  spec.summary       = %q{Ruby wrapper for the atalogics logistics API.}
  spec.description   = %q{Wrapper for atalogics API, book shipments, check addresses...}
  spec.homepage      = "https://github.com/atalanda/atalogics_api"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'pry-alias'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'redis'
  spec.add_dependency "httparty", "~> 0.8.3"
end
