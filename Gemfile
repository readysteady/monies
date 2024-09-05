source 'https://rubygems.org'

group :test do
  if RUBY_ENGINE == 'jruby'
    gem 'activerecord', '~> 7.1.0'
  else
    gem 'activerecord', '~> 7'
  end
  gem 'bigdecimal', '~> 3'
  gem 'percentage', '~> 2'
  gem 'rspec-core', '~> 3'
  gem 'rspec-expectations', '~> 3'
  gem 'sequel', '~> 5'
  gem 'simplecov'
  gem 'sqlite3', '~> 2', platform: :ruby
end

platforms :jruby do
  gem 'jdbc-sqlite3', github: 'jruby/activerecord-jdbc-adapter', glob: 'jdbc-sqlite3/jdbc-sqlite3.gemspec', group: :test
end
