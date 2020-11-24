# frozen_string_literal: true

require 'connection_pool'
require 'pry' # TODO: if APP_ENV == 'development'
require 'redisearch-rb'
require 'sinatra'
require 'sinatra/json'

class SearchApp < Sinatra::Base

  configure :production, :staging, :development do
    enable :logging
    # setup redis search gem
    set :redis, ConnectionPool.new(size: 2) { Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis/0')) }
  end

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
        clauses[:sortby] = [sort_field, sort_order_param]
      end
      if (limit = params['limit'])
        # limit is offset, num
        # https://oss.redislabs.com/redisearch/Commands/#ftsearch
        clauses[:limit] = ['0', limit]
      end

      json redisearch_client.search(filter, clauses)
    end
  end
end
