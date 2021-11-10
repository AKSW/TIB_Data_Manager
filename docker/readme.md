# CKAN Docker image

The whole CKAN deployment is using docker and docker-compose.
The idea is to clone this repository, set server specifics via the .env file and then run `docker-compose up -d`.

## Manual container building
These steps are only necessary when the corresponding code was changed.
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
The other images get pulled from docker hub or the github registry.

## Docker-compose environment
* BASE_DOMAIN needs to be set to the correct domain, which is used by ckan and a sparql.BASE_DOMAIN subdomain is then used for virtusoso
* VIRTUOSO_USER and VIRTUOSO_PASSWORD are for the virtusoso credentials
* GIT_REPO, GIT_EMAIL, GIT_NAME, CRON_JOB and GRAPH_URI are used in the import container

### HTTPS

The docker-compose file was created to be used with the JWilder nginx container and a lets encrypt companion.
Thats why VIRTUAL_HOST, VIRTUAL_PORT and LETSENCRYPT_HOST are set. For more information please have a look on https://hub.docker.com/r/jwilder/nginx-proxy

## First execution
CKAN is expecting to connect directly to the database. In the case of the preloaded image this is not possible since postgresql needs to execute *.sql scripts, so it is recommended to first run the database, and when the databases are ready, start ckan.

```sh
$ docker-compose up -d pusher redis solr postfix postgresql dataretrieval virtuoso
$ docker-compose up ckan
```

## Run
Execute the docker-compose file.
```sh
$ docker-compose up -d
```
Please note that this also starts the aggregation of metadata into virtuoso via the metadataimporter container and the import container.

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

# Issues

SSL error
development fix:
```
import ssl

ssl._create_default_https_context = ssl._create_unverified_context
```
