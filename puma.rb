# frozen_string_literal: true

env = ENV.fetch('RACK_ENV', 'development')
port = ENV.fetch('PORT', 80)
environment env
max_threads = ENV.fetch('MAX_THREADS', 2).to_i
threads 1, max_threads
bind "tcp://0.0.0.0:#{port}"
