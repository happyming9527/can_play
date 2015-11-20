# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'can_play/version'

Gem::Specification.new do |spec|
  spec.name          = "can_play"
  spec.version       = CanPlay::VERSION
  spec.authors       = ["happyming9527"]
  spec.email         = ["happyming9527@gmail.com"]

  spec.summary       = %q{a permission system.}
  spec.description   = %q{control user's permissions based on role and resource.}
  spec.homepage      = "https://github.com/happyming9527/can_play"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency 'cancancan', "~> 1.12"
  spec.add_dependency 'consul', "~> 0.12"
  spec.add_dependency 'ror_hack', "~> 0.1 "
end
