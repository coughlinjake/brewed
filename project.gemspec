# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'project/version'

Gem::Specification.new do |spec|
  spec.name          = 'project'
  spec.version       = Project::VERSION
  spec.authors       = ['Jake Coughlin']
  spec.email         = ['coughlin.jake@gmail.com']
  spec.summary       = %q{Project support code.}
  spec.description   = %q{Some of the basic framework code which supports every project.}
  spec.homepage      = 'https://github.com/coughlinjake/project'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',  '~> 1.6'
  spec.add_development_dependency 'rake',     '~> 10.3.1'
  spec.add_development_dependency 'yard',     '~> 0.8.7.4'
  
  spec.add_dependency 'psych',                '~> 2.0.5'
  spec.add_dependency 'unidecoder',           '~> 1.1.2'
end
