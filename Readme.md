# Installation

We only support running via Docker and Docker Compose, use those.

## Create the seed data

1. Download the subject data export from [ASM data exports lab page](https://www.zooniverse.org/lab/4973/data-exports)
    * Add the file to the `./subject_data/` directory
2. Convert a subject export file to redis FT search index cmds
    * `docker-compose run --rm search_api bash`
3. From within the above container, run the conversion script
    * `ruby convert_subject_export_to_redis_cmds.rb -i subject_data/anti-slavery-manuscripts-subjects.csv -s 15582`

## Usage

1. Run a redis cli and ensure the redis search container is started
    * `docker-compose run --rm redis-bash redis-cli -h redis`
2. Load the redis ft search data constructed in the seed rdata
    * `docker-compose run --rm redis-bash bash -c "cat /usr/src/code/redis_search_index.txt | redis-cli -h redis"`

    * Alternatively launch a bash shell in the redis container
      * `docker-compose run --rm redis-bash bash`

        Seed the search index with data from above
          * `cat /usr/src/code/redis_search_index.txt | redis-cli -h redis`
          * `exit`

5. Run the API over the redis FT search index
    * `docker-compose run --rm --service-ports search_api`

## Search API Syntax

* all records but sorted on a field

  * http://localhost:3000/search/15582?sort_field=title&sort_order=asc
  * http://localhost:3000/search/15582?sort_field=title&sort_order=desc

* only the first 5 records

  * http://localhost:3000/search/15582?limit=5

* a field (title) with a term

  * http://localhost:3000/search/15582?filter_field=@title:oppression&sort_field=title&sort_order=asc&limit=5

* a field (title) with term and wildcard

  * http://localhost:3000/search/15582?filter_field=@title:sam*&sort_field=title&sort_order=asc&limit=50

* all fields with a term

  * http://localhost:3000/search/15582?filter_field=record&sort_field=title&sort_order=asc&limit=1

* all fields with term and wildcard

  * http://localhost:3000/search/15582?filter_field=sam*&sort_field=title&sort_order=asc&limit=10
