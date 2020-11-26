# frozen_string_literal: true

require 'connection_pool'
require 'pry' if %w[development test].include?(ENV['RACK_ENV'])
require 'rack/cors'
require 'redisearch-rb'
require 'sinatra'
require 'sinatra/json'

class SearchApp < Sinatra::Base
  configure :production, :staging, :development do
    enable :logging
    # setup global redis connection pool (match num of puma server threads)
    # for use with the search client in the request handlers
    max_threads = ENV.fetch('MAX_THREADS', 2).to_i
    set :redis, ConnectionPool.new(size: max_threads) { Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis/0')) }
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
  options '/search/:subject_set_id' { 200 }
  # search route for redis FT index
  get '/search/:subject_set_id' do
    index_key = "set-id-#{params['subject_set_id']}"

    settings.redis.with do |redis|
      redisearch_client = RediSearch.new(index_key, redis)
      # all docs search by default (add filtering later)
      filter = params['filter_field'] || '*'
      clauses = {}
      if (sort_field = params['sort_field'])
        sort_order_param = [params['sort_order']&.to_sym].compact

        # https://github.com/npezza93/redi_search#query-level-clauses
        sort_order = (%i[asc desc] & sort_order_param).first || :asc
        clauses[:sortby] = [sort_field, sort_order]
      end
      if (limit = params['limit'])
        # limit is offset, num
        # https://oss.redislabs.com/redisearch/Commands/#ftsearch
        clauses[:limit] = ['0', limit]
      end

      json redisearch_client.search(filter, clauses)
    end
  rescue  Redis::CommandError => e
    [404, json({ error: e.message })]
  end
end
