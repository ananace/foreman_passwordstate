# frozen_string_literal: true

require File.join File.expand_path('lib', __dir__), 'foreman_passwordstate/version'

Gem::Specification.new do |spec|
  spec.name          = 'foreman_passwordstate'
  spec.version       = ForemanPasswordstate::VERSION
  spec.authors       = ['Alexander Olofsson']
  spec.email         = ['alexander.olofsson@liu.se']

  spec.summary       = 'A Foreman plugin for handling passwords with Passwordstate'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/ananace/foreman_passwordstate'
  spec.license       = 'MIT'

  spec.files         = Dir['{app,config,db,lib}/**/*.*'] + %w[LICENSE.txt Rakefile README.md]

  spec.add_dependency 'deface'
  spec.add_dependency 'passwordstate', '~> 0'
end
