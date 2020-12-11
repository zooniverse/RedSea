# frozen_string_literal: true

require 'connection_pool'
require 'redisearch-rb'

module Api
  class SearchClient
    attr_reader :redis, :params, :status, :results

    def self.connection_pool_size
      ENV.fetch('MAX_THREADS', 2).to_i
    end

    def self.redis_url
      ENV.fetch('REDIS_URL', 'redis://redis/0')
    end

    # setup global redis connection pool (match num of puma server threads)
    # for use with the search client in the request handlers
    def self.redis_connection_pool
      @redis_connection_pool ||= ConnectionPool.new(size: connection_pool_size) {
        Redis.new(url: redis_url)
      }
    end

    def initialize(params)
      @params = params
      @status = 200
      @results = nil
    end

    def query_ft_index(index_key)
      self.class.redis_connection_pool.with do |redis_conn|
        redisearch_client = RediSearch.new(index_key, redis_conn)

        # run the search query against the redis FT index
        @results = redisearch_client.search(filter, clauses)
        true
      end
    rescue Redis::CommandError => e
      # handle errors like index doesn't exist
      #  here we can expand on the status code
      #  to handle different failure modes (error classes)
      @status = 404
      @results = { error: e.message }
      false
    end

    private

    # allow field filtering, all docs search by default
    def filter
      params['filter_field'] || '*'
    end

    # setup our search clause options (sort, limit etc)
    def clauses
      { sortby: sort_by_params, limit: limit_params }.compact
    end

    def sort_by_params
      return unless params['sort_field']

      sort_order_param = [params['sort_order']&.to_sym].compact

      # https://github.com/npezza93/redi_search#query-level-clauses
      sort_order = (%i[asc desc] & sort_order_param).first || :asc
      [params['sort_field'], sort_order]
    end

    def limit_params
      return unless params['limit']

      # limit is offset, num
      # https://oss.redislabs.com/redisearch/Commands/#ftsearch
      ['0', params['limit']]
    end
  end
end