source "https://rubygems.org"

gem "bootsnap", require: false
gem "image_processing", "~> 2.1"
gem "importmap-rails"
gem "jbuilder"
# Transitive dependency, floored for CVE-2026-71847 (GHSA-9hj4-r449-hfvc) and
# held on the 2.x line: json 3.0 is a days-old major that rejects duplicate
# keys, drops the legacy aliases and turns unknown options into ArgumentError,
# none of which Rails 8.1 has been validated against.
gem "json", "~> 2.21", ">= 2.21.2"
gem "kamal", require: false
gem "propshaft"
gem "puma", ">= 5.0"
gem "rails", "~> 8.1.3"
gem "rdoc", "8.0.0"
# image_processing 2.x turned mini_magick/ruby-vips into soft dependencies, so
# the vips backend Active Storage defaults to under config.load_defaults 8.1
# has to be declared here. It is a boot requirement, not just a per-`variant`
# one: Active Storage's after_initialize resolves variant_transformer to
# Transformers::Vips, whose file requires image_processing/vips -> ruby-vips.
#
# `require: false` because ruby-vips binds libvips over FFI at require time
# (`ffi_lib FFI.library_name("vips", 42)`), so letting Bundler.require load it
# from config/application would hard-fail any process that stops there on a box
# without libvips — CI's scan_js job runs `bin/importmap audit`, which does
# exactly that and never apt-installs libvips. Active Storage requires it
# itself inside a rescue LoadError that downgrades a missing libvips to a log
# warning, so full boot stays safe with or without the library present.
gem "ruby-vips", require: false
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"
gem "sqlite3", ">= 2.1"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "thruster", require: false
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 8.0"
end
