#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

task :spec do
  $LOAD_PATH.unshift('spec')
  Dir.glob('./spec/**/*_spec.rb') { |f| require f }
end

task :default => [:spec]
