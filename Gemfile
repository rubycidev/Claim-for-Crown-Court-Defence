source 'https://rubygems.org'
ruby '3.1.3'
gem 'active_model_serializers', '~> 0.10.13'
gem 'amoeba',                 '~> 3.2.0'
gem 'auto_strip_attributes',  '~> 2.6.0'
gem 'aws-sdk-s3',             '~> 1'
gem 'aws-sdk-sns',            '~> 1'
gem 'aws-sdk-sqs',            '~> 1'
gem 'awesome_print'
gem 'bootsnap', require: false
gem 'cancancan',              '~> 3.5'
gem 'cocoon',                 '~> 1.2.15'
gem 'devise', '~> 4.9.1'
gem 'dotenv-rails'
gem 'factory_bot_rails', '~> 6.2.0'
gem 'faker',                  '~> 3.1.1'
gem 'govuk_design_system_formbuilder', '~> 3.3'
gem 'govuk_notify_rails', '~> 2.2.0'
gem 'grape', '~> 1.7.0'
gem 'grape-entity',           '~> 1.0.0'
gem 'grape-papertrail',       '~> 0.2.0'
gem 'grape-swagger', '~> 1.6.0'
gem 'grape-swagger-rails', '~> 0.4.0'
gem 'haml-rails', '~> 2.1.0'
gem 'hashdiff',               '>= 1.0.0.beta1', '< 2.0.0'
gem 'hashie-forbidden_attributes', '>= 0.1.1'
gem 'jquery-rails', '~> 4.5.1'
gem 'json-schema',            '~> 3.0.0'
gem 'jsbundling-rails'
gem 'nokogiri',               '~> 1.14'
gem 'kaminari',               '>= 1.2.1'
gem 'libreconv',              '~> 0.9.5'
gem 'logstasher',             '2.1.5'
gem 'logstuff',               '0.0.2'
gem 'net-imap'
gem 'net-pop'
gem 'net-smtp'
gem 'paper_trail', '~> 14.0.0'
gem 'pg',                     '~> 1.4.6'
gem 'rails', '~> 6.1.7'
gem 'redis',                  '~> 5.0.6'
gem 'rubyzip'
gem 'config',                 '~> 4.1' # this gem provides our Settings.xxx mechanism
gem 'remotipart',             '~> 1.4'
gem 'rest-client',            '~> 2.1' # needed for scheduled smoke testing plus others
gem 'scheduler_daemon'
gem 'sentry-rails', '~> 5.5', '>= 5.5.0'
gem 'sentry-sidekiq', '~> 5.8'
gem 'sprockets-rails', '~> 3.4.2'
gem 'state_machines-activerecord'
gem 'state_machines-audit_trail'
gem 'tzinfo-data'
gem 'zendesk_api'  ,           '1.37.0'
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-failures', '~> 1.0'
gem 'utf8-cleaner',            '~> 1.0'
gem 'colorize'
gem 'shell-spinner', '~> 1.0', '>= 1.0.4'
gem 'ruby-progressbar'
gem 'geckoboard-ruby'
gem 'laa-fee-calculator-client', '~> 1.4'
gem 'active_storage_validations'
gem 'faraday', '~> 1.10'
gem 'faraday_middleware', '~> 1.2'

group :production, :devunicorn do
  gem 'unicorn-rails', '2.2.1'
  gem 'unicorn-worker-killer', '~> 0.4.5'
end

group :development, :devunicorn, :test do
  gem 'annotate'
  gem 'brakeman', :require => false
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug'
  gem 'listen', '~> 3.8.0'
  gem 'meta_request'
  gem 'parallel_tests'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'puma'
  gem 'rack-livereload', '~> 0.3.17'
  gem 'rspec-rails', '~> 6.0.1'
  gem 'rspec-collection_matchers'
  gem 'rspec_junit_formatter'
  gem 'net-ssh', '~> 7.1'
  gem 'net-scp', '>= 4.0.0.rc1'
  gem 'rubocop', '~> 1.49'
  gem 'rubocop-rspec'
  gem 'rubocop-rails'
  gem 'rubocop-performance'
  gem 'site_prism', '~> 3.7', '>= 3.7.3'
end

group :test do
  gem 'axe-core-cucumber', '~> 4.6'
  gem 'capybara-selenium'
  gem 'capybara', '~> 3.39'
  gem 'cucumber-rails', '~> 2.6.1', require: false
  gem 'database_cleaner'
  gem 'i18n-tasks'
  gem 'json_spec'
  gem 'launchy', '~> 2.5.2'
  gem 'rails-controller-testing'
  gem 'rspec-html-matchers', '~> 0.10.0'
  gem 'rspec-mocks'
  gem 'shoulda-matchers', '>= 4.0.0.rc1'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webdrivers', '~> 5.2', require: false
  gem 'webmock'
end
