# frozen_string_literal: true

source 'https://rubygems.org'

# Logger will disappear from the Ruby standard library in Ruby 3.5.0
gem 'logger', '~> 1.7'

group :development, :test do
  gem 'debug', '>= 1.0.0'
  gem 'rspec'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'simplecov'
end

group :development do
  gem 'yard', '~> 0.9.38'

  # Yard dependencies:
  gem 'rack', '~> 3.2'
  gem 'rackup', '~> 2.3'
  gem 'webrick', '~> 1.9'
end
