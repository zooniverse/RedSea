# frozen_string_literal: true

require 'csv'
require 'json'
require 'optparse'
require 'pry'

Options = Struct.new(:input_file, :subject_set_id)
options = Options.new

opt_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: convert_subject_export_to_redis_cmds.rb [options]'

  opts.on('-i', '--input-file INPUT_FILE', 'Required: Specify the subject export file to convert') do |input_file|
    options.input_file = input_file
  end

  opts.on('-s', '--set-id SET_ID', Integer, 'Required: Specify a subject-set-id to filter the input data') do |set_id|
    options.subject_set_id = set_id
  end

  opts.on('-h', '--help', 'Prints this help text') do
    puts opts
    exit
  end
end

opt_parser.parse!

# print the help message if missing required params
opt_parser.parse! %w[--help] if options.input_file.nil? || options.subject_set_id.nil?

# here is where the fun happens
known_metadata_fields = %w[date title creators]
found_docs = {}
redis_out_file_name = 'redis_search_index.txt'

# read the input csv file
CSV.foreach(options.input_file, headers: true) do |row|
  # filter on the appropriate subject_set_id
  next unless row['subject_set_id'] == options.subject_set_id.to_s

  metadata = JSON.parse(row['metadata'])
  # handle different casing on the metadata keys (user supplied)
  matching_metadata_fields = metadata.keys.select { |key| known_metadata_fields.include? key.downcase }
  found_docs[row['subject_id']] = metadata.slice(*matching_metadata_fields)
end

# write out the redis cmds to a file
File.open(redis_out_file_name, 'wb') do |out_file|
  # create a set of cmds to construct the redis search data set:
  # 1. create the FT search index
  search_index_name = "set-id-#{options.subject_set_id}"
  search_index_create_stmt = "FT.CREATE #{search_index_name} PREFIX 1 doc: SCHEMA id TEXT SORTABLE"
  known_metadata_fields.each do |field|
    # https://oss.redislabs.com/redisearch/Commands/#ftcreate
    search_index_create_stmt += " #{field} TEXT SORTABLE"
  end
  # write create statement out
  search_index_drop_stmt = "FT.DROPINDEX #{search_index_name} DD"
  out_file.puts search_index_drop_stmt
  out_file.puts search_index_create_stmt
  # 2. create the index docs
  found_docs.each.with_index do |(id, doc), index|
    add_doc_to_ft_schema_stmt = "hset doc:#{index+1} id \"#{id}\""
    doc.each do |key, value|
      # remove illegal quote statements for redis cmds
      single_quoted_value = value.gsub('"', "'")
      add_doc_to_ft_schema_stmt += " #{key} \"#{single_quoted_value}\""
    end

    # write each index doc to the file
    out_file.puts add_doc_to_ft_schema_stmt
  end
end