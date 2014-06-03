# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wad/version'

Gem::Specification.new do |spec|
  spec.name          = 'wad'
  spec.version       = Wad::VERSION
  spec.authors       = ['Jake Coughlin']
  spec.email         = ['coughlin.jake@gmail.com']
  spec.summary       = %q{Scrunch your source into a wad.}
  spec.description   = %q{"Project" was taken... as was "bale"... so now I write wads.}
  spec.homepage      = 'https://github.com/coughlinjake/project'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',              '~> 1.6'
  spec.add_development_dependency 'rake',                 '~> 10.3.1'
  spec.add_development_dependency 'minitest',             '>= 5.3.4'
  spec.add_development_dependency 'minitest-reporters',   '>= 1.0.0'
  spec.add_development_dependency 'yard',                 '~> 0.8.7.4'

  spec.add_dependency 'psych',                            '~> 2.0.5'
  spec.add_dependency 'unidecoder',                       '~> 1.1.2'
end
