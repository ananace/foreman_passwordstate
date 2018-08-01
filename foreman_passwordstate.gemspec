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

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'deface', '< 2.0'
  spec.add_dependency 'passwordstate', '~> 0'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end
