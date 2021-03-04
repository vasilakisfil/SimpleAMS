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
  spec.required_ruby_version = '>= 2.4'

  spec.add_development_dependency 'faker', '~> 2.16'
  spec.add_development_dependency 'pry', '~> 0.14.0'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.93.1'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
end
