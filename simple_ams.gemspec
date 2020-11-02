lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_ams/version'

Gem::Specification.new do |spec|
  spec.name          = 'simple_ams'
  spec.version       = SimpleAMS::VERSION
  spec.authors       = ['Filippos Vasilakis']
  spec.email         = ['vasilakisfil@gmail.com']

  spec.summary       = 'ActiveModel Serializers, simplified.'
  spec.description   = 'ActiveModel Serializers, simplified.'
  spec.homepage      = 'https://github.com/vasilakisfil/SimpleAMS'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'faker', '~> 1.8.5'
  spec.add_development_dependency 'pry', '~> 0.11.3'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.93.1'
  spec.add_development_dependency 'simplecov'
end
