# NOTE: These are development-only dependencies
source "https://rubygems.org"

# None of these can actually be used in a development copy of dev
# They are all for CI and tests
# `dev` uses no gems
group :development, :test do
  gem 'rake'
  gem 'pry-byebug'
  gem 'byebug'
  gem 'prettier', github: "prettier/plugin-ruby", branch: "master"
  gem 'rubocop-shopify', require: false
  gem 'rubocop-minitest', require: false
end

group :test do
  gem 'mocha', require: false
  gem 'minitest', '>= 5.0.0', require: false
  gem 'minitest-reporters', require: false
  gem 'minitest-fail-fast', require: false
  gem 'fakefs', '>= 1.0', require: false
  gem 'webmock', require: false
  gem 'timecop', require: false
end
