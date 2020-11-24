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
    * `docker-compose run --rm redis-bash cat /usr/src/code/redis_search_index.txt | redis-cli -h redis`
3. From within the above container, seed the search index with data from above
    * `cat /usr/src/code/redis_search_index.txt | redis-cli -h redis`
4. From within the above container, seed the example redis FT search index data and cmds
    * `grep -Ev "^#|^$" /usr/src/code/seed_cmds.txt | redis-cli -h redis`
5. Run the API over the redis FT search index
    * `docker-compose run --rm --service-ports search_api`
