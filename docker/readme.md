# CKAN Docker image

## Installation 
Build ckan_base ckan_base
```sh
$ docker build ./ckan_base -t ckan_base
```
Build ckan with plugins
```sh
$ docker build ../. -t ckan
```
Build postgresql or postgresql:loaded 
```sh
$ docker build ./postgresql/ -t postgresql
$ docker build ./postgresql-loaded/ -t postgresql-loaded
```
## Docker-compose Docker
* docker-compose is configured by default to work with postgresql:loaded  docker-compose.yml，postgresql:loaded image postgresql,
* CKAN_SITE_URL needs to be set to the correct ip/domain docker-compose.yml，“ CKAN_SITE_URL” ip

## First execution
CKAN is expecting to connect directly to the database. In the case of the preloaded image this is not possible since postgresql needs to execute *.sql scripts, so it is recommended to first run the database, and when the databases are ready, start ckan.

```sh
$ docker-compose up -d pusher redis solr db
$ docker-compose up ckan
```

## Run
Execute the docker-compose file.
```sh
$ docker-compose up
```

## Default credentials
```
ckan = admin:admin
db = ckan:ckan
```

## Useful Commands
### [CKAN] Create user or admin account 
User accounts and admin accounts can be created with paster command.

```sh
# Go inside the container
$ docker exec -ti ckan bash

# Create new user
$ ckan-paster --plugin=ckan user -c $CKAN_CONFIG/ckan.ini add username [ email=username@email.com password=password ]

# Create new admin
$ ckan-paster --plugin=ckan sysadmin -c $CKAN_CONFIG/ckan.ini add username [ email=username@email.com password=password ]
```
Either by going inside the cointainer ckan, or running it with a modified entrypoint.
### [CKAN] Rebuild index
Rebuild the index to make search engine match the current dataset.

```sh
$ ckan-paster --plugin=ckan search-index rebuild -c $CKAN_CONFIG/ckan.ini
```
