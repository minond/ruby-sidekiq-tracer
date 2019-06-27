# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sidekiq/tracer/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-opentracing"
  spec.version       = Sidekiq::Tracer::VERSION
  spec.authors       = ["iaintshine"]
  spec.email         = ["bodziomista@gmail.com"]
  spec.license       = "Apache-2.0"

  spec.summary       = %q{OpenTracing instrumentation for Sidekiq.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/iaintshine/ruby-sidekiq-tracer"

  spec.required_ruby_version = ">= 2.2.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://gems.internal.mx"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'opentracing'
  spec.add_dependency 'sidekiq'

  spec.add_development_dependency "opentracing_test_tracer"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
