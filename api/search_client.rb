# frozen_string_literal: true

require 'redisearch-rb'

module Api
  class SearchClient
    attr_reader *%i[redis params ok results error_message]

    def initialize(redis, params)
      @redis = redis
      @params = params
      @ok = true
      @results = nil
      @error_message = nil
    end

    # this can be extracted to a search class
    # to allow us to switch the backend search db / client out
    def query_ft_index(index_key)
      # use the redis connection pool
      redis.with do |redis_conn|
        redisearch_client = RediSearch.new(index_key, redis_conn)

        # query the redis db
        @results = redisearch_client.search(filter, clauses)
        true
      end
    rescue Redis::CommandError => e
      @ok = false
      # handle errors like index doesn't exist
      # respond with the error msg
      @error_message = e.message
      false
    end

    def ok?
      ok
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