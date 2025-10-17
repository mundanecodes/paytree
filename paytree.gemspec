require_relative "lib/paytree/version"

Gem::Specification.new do |spec|
  spec.name = "paytree"
  spec.version = Paytree::VERSION
  spec.authors = ["Charles Chuck"]
  spec.email = ["chalcchuck@gmail.com"]

  spec.summary = "A Ruby wrapper for the Mpesa API in Kenya."
  spec.description = <<~DESC
    Paytree is a lightweight Ruby wrapper for the full Mpesa API suite in Kenya - including B2C, C2B, STK Push and more. It supports certificate encryption, clean facades, and a pluggable adapter system (e.g. Daraja, Airtel..). Built for Rails and pure Ruby apps.
  DESC
  spec.homepage = "https://github.com/mundanecodes/paytree"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mundanecodes/paytree"
  spec.metadata["changelog_uri"] = "https://github.com/mundanecodes/paytree/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://github.com/mundanecodes/paytree/blob/main/README.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/mundanecodes/paytree/issues"
  spec.metadata["wiki_uri"] = "https://github.com/mundanecodes/paytree/wiki"
  spec.metadata["mailing_list_uri"] = "https://github.com/mundanecodes/paytree/discussions"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["keywords"] = "mpesa,mpesa-api,b2c,stk-push,mobile-money,payments,daraja"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features|bin|exe)/}) || f.include?(".git") || f.end_with?(".gem")
    end
  end

  spec.require_paths = ["lib"]

  # Runtime deps
  spec.add_dependency "httpx", "~> 1.0"

  # Dev/test deps
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "rubocop-rails-omakase"
end
