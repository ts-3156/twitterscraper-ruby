require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name          = "twitterscraper-ruby"
  spec.version       = Twitterscraper::VERSION
  spec.authors       = ["ts-3156"]
  spec.email         = ["ts_3156@yahoo.co.jp"]

  spec.summary       = %q{A gem  to scrape Tweets}
  spec.description   = %q{A gem  to scrape Tweets}
  spec.homepage      = "https://github.com/ts-3156/twitterscraper-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
end
