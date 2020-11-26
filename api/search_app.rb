# frozen_string_literal: true

require 'pry' if %w[development test].include?(ENV['RACK_ENV'])
require 'rack/cors'
require_relative 'search_client'
require 'sinatra'
require 'sinatra/json'

module Api
  class SearchApp < Sinatra::Base
    configure :production, :staging, :development do
      enable :logging
    end

    # setup CORS for use across zooniverse / local dev domains
    use Rack::Cors do
      cors_origins = ENV.fetch('CORS_ORIGINS', '([a-z0-9-]+\.zooniverse\.org)')
      allow do
        origins %r{^https?://#{cors_origins}(:\d+)?$}
        resource '*', headers: :any, methods: :get
      end
    end

    # CORS preflight options request handler
    options '/search/:subject_set_id' do
      200
    end
    # search route for redis FT index
    get '/search/:subject_set_id' do
      index_key = "set-id-#{params['subject_set_id']}"

      search_client = SearchClient.new(params)
      search_client.query_ft_index(index_key)

      # serailize the response
      [search_client.status, json(search_client.results)]
    end
  end
end
