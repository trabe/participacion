source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.4'
# Use PostgreSQL
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

gem 'devise'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2', '~> 0.2.7'
gem 'omniauth-cas'

gem 'kaminari'
gem 'ancestry'
gem 'acts-as-taggable-on'
gem 'responders'
gem 'foundation-rails'
gem 'foundation_rails_helper'
gem 'acts_as_votable'
gem 'simple_captcha2', require: 'simple_captcha'

gem 'ckeditor'
gem 'non-stupid-digest-assets'

gem 'cancancan'
gem 'social-share-button', git: 'https://github.com/huacnlee/social-share-button.git', ref: 'e46a6a3e82b86023bc'
gem 'initialjs-rails', '0.2.0.1'
#gem 'unicorn'
gem 'paranoia'
gem 'rinku', require: 'rails_rinku'
gem 'savon'
gem 'dalli'
gem 'rollbar', '~> 2.4.0'
gem 'delayed_job_active_record', '~> 4.1.0'
gem 'daemons'
gem 'devise-async'
#gem 'newrelic_rpm', '~> 3.14'
gem 'whenever', require: false

gem 'ahoy_matey', '~> 1.2.1'
gem 'groupdate'   # group temporary data

gem 'browser'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry-byebug'
  gem 'pry-remote'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'rspec-rails', '~> 3.0'
  gem 'capybara'
  gem 'factory_girl_rails'
  gem 'fuubar'
  gem 'launchy'
  gem 'quiet_assets'
  gem 'letter_opener_web', '~> 1.3.0'
  gem 'i18n-tasks'
  gem 'capistrano', '3.4.0',           require: false
  gem "capistrano-bundler", '1.1.4',   require: false
  gem "capistrano-rails", '1.1.5',     require: false
  gem "capistrano-rvm",                require: false
  gem "capistrano-passenger",          require: false
  gem 'capistrano3-delayed-job', '~> 1.0'
  gem "bullet"
  gem "faker"
end

group :test do
  gem 'database_cleaner'
  gem 'poltergeist'
  gem 'coveralls', require: false
end

group :test do
  gem 'email_spec'
end
