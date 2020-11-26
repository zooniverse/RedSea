# frozen_string_literal: true

require_relative 'api/search_app'
require 'bundler/setup'

APP_ENV = ENV['RACK_ENV'] || 'development'

Bundler.require(:default, APP_ENV.to_sym)

run Api::SearchApp
