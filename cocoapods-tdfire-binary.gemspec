# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-tdfire-binary/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-tdfire-binary'
  spec.version       = CocoapodsTdfireBinary::VERSION
  spec.authors       = ['tripleCC']
  spec.email         = ['triplec.linux@gmail.com']
  spec.description   = %q{cocoapods-tdfire-binary is a plugin which helps developer switching there project dependency between source and binary.}
  spec.summary       = %q{cocoapods-tdfire-binary is a plugin which helps developer switching there project dependency between source and binary.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-tdfire-binary'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '~> 12.0'

  spec.add_dependency 'cocoapods', '~> 1.4'
  spec.add_dependency 'colorize', '~> 0.8'
  
end
