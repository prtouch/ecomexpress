# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ecomexpress/version'

Gem::Specification.new do |spec|
  spec.name          = "ecomexpress"
  spec.version       = Ecomexpress::VERSION
  spec.authors       = ["CJ"]
  spec.email         = ["chirag7jain@gmail.com"]

  spec.summary       = %q{Ecomexpress Web Services}
  spec.description   = %q{Provides an interface to Ecomexpress Web Services}
  spec.homepage      = "https://github.com/chirag7jain/ecomexpress"
  spec.licenses      = ["MIT"]

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'nokogiri', ">= 1.5.11"
  spec.add_dependency 'httparty', ">= 0.13.5"
  spec.add_dependency 'nori', ">= 2.4.0"

  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "rake", "~> 13.0.1"
  
  spec.required_ruby_version = ">= 1.9.3"
end
