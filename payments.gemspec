require_relative "lib/payments/version"

Gem::Specification.new do |spec|
  spec.name = "payments"
  spec.version = Payments::VERSION
  spec.authors = ["Charles Chuck"]
  spec.email = ["chalcchuck@gmail.com"]

  spec.summary = "Rails-optional payments abstraction for M-Pesa (Daraja) and more."
  spec.description = "Clean, adapter-based Ruby DSL for mobile money integrations like M-Pesa via Daraja, with future provider support (Tingg, Airtel, Cellulant)."
  spec.homepage = "https://github.com/mundanecode/payments"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mundanecode/payments"
  spec.metadata["changelog_uri"] = "https://github.com/mundanecode/payments/blob/main/CHANGELOG.md"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features|bin|exe)/}) || f.include?(".git")
    end
  end

  spec.require_paths = ["lib"]

  # Runtime deps
  spec.add_dependency "faraday", "~> 2.0"

  # Dev/test deps
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "dotenv", "~> 2.8"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "rubocop-rails-omakase"
end
