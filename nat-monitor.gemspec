# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nat-monitor/version'

Gem::Specification.new do |spec|
  spec.name          = 'nat-monitor'
  spec.version       = EtTools::NatMonitor::VERSION
  spec.authors       = ['Eric Herot']
  spec.email         = ['eric.github@herot.com']
  spec.summary       = 'A service for providing an HA NAT in EC2'
  spec.description   = spec.summary
  spec.homepage      = ''
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'gemfury'

  spec.add_runtime_dependency 'fog', '~> 1.23'
end
