#!/bin/sh
set -e

CONFIG="${CKAN_CONFIG}/ckan.ini"
TIMER=5

abort () {
  echo "$@" >&2
  exit 1
}

set_environment () {
  export CKAN_SITE_ID=${CKAN_SITE_ID}
  export CKAN_SITE_URL=${CKAN_SITE_URL}
  export CKAN_SQLALCHEMY_URL=${CKAN_SQLALCHEMY_URL}
  export CKAN_SOLR_URL=${CKAN_SOLR_URL}
  export CKAN_REDIS_URL=${CKAN_REDIS_URL}
  export CKAN_STORAGE_PATH=/var/lib/ckan
  export CKAN_DATAPUSHER_URL=${CKAN_PUSHER_URL}
  export CKAN_DATASTORE_WRITE_URL=${CKAN_DATASTORE_WRITE_URL}
  export CKAN_DATASTORE_READ_URL=${CKAN_DATASTORE_READ_URL}
  export CKAN_SMTP_SERVER=${CKAN_SMTP_SERVER}
  export CKAN_SMTP_STARTTLS=${CKAN_SMTP_STARTTLS}
  export CKAN_SMTP_USER=${CKAN_SMTP_USER}
  export CKAN_SMTP_PASSWORD=${CKAN_SMTP_PASSWORD}
  export CKAN_SMTP_MAIL_FROM=${CKAN_SMTP_MAIL_FROM}
  export CKAN_MAX_UPLOAD_SIZE_MB=${CKAN_MAX_UPLOAD_SIZE_MB}
}

# Note that this only gets called if there is no config, see below!
write_config () {
  ckan generate config "$CONFIG"

  ckan -c "$CONFIG" config-tool "$CONFIG" -s DEFAULT -e "debug = false"
  # The variables above will be used by CKAN, but
  # in case want to use the config from ckan.ini use this
  ckan -c "$CONFIG" config-tool "$CONFIG" -e \
     "sqlalchemy.url = ${CKAN_SQLALCHEMY_URL}" \
     "solr_url = ${CKAN_SOLR_URL}" \
     "ckan.redis.url = ${CKAN_REDIS_URL}" \
     "ckan.storage_path = ${CKAN_STORAGE_PATH}" \
     "ckan.site_url = ${CKAN_SITE_URL}" \
     "ckan.datapusher.url = ${CKAN_PUSHER_URL}" \
     "ckan.datastore.write_url = ${CKAN_DATASTORE_WRITE}" \
     "ckan.datastore.read_url = ${CKAN_DATASTORE_READ}" \
     "smtp.server = postfix" \
     "ckan.views.default_views = image_view text_view recline_view  " \
     "smtp.mail_from = admin@datahub.com" \
     "ckan.plugins = stats text_view image_view recline_view resource_proxy datastore datapusher webpage_view   STREAMtheme" \
     "ckan.datapusher.formats = csv xls xlsx tsv application/csv application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" \
     "ckan.max_resource_size = 104857600" \
     "ckan.cors.origin_allow_all = True"
}

# Get or create CKAN_SQLALCHEMY_URL
if [ -z "$CKAN_SQLALCHEMY_URL" ]; then
  abort "ERROR: no CKAN_SQLALCHEMY_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_SOLR_URL" ]; then
    abort "ERROR: no CKAN_SOLR_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_REDIS_URL" ]; then
    abort "ERROR: no CKAN_REDIS_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_PUSHER_URL" ]; then
    abort "ERROR: no CKAN_PUSHER_URL specified in docker-compose.yml"
fi

set_environment

# We are not waiting until the database is ready.
# This could be improved.
# wait for postgres db to be available, immediately after creation
# its entrypoint creates the cluster and dbs and this can take a moment

# If we don't already have a config file, bootstrap
if [ ! -e "$CONFIG" ]; then
  write_config

  # Initializes the Database
  ckan -c "$CONFIG" db init

  # Enable Plugins: harvest and dcat
  ckan -c "$CONFIG" config-tool "$CONFIG" -e \
     "ckan.plugins = stats text_view image_view recline_view resource_proxy datastore datapusher webpage_view   harvest ckan_harvester dcat dcat_json_interface dcat_rdf_harvester dcat_json_harvester structured_data STREAMtheme dataretrieval tags qualityreports"
  ckan -c "$CONFIG" harvester initdb
  ckan -c "$CONFIG" config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.type = redis"
  ckan -c "$CONFIG" config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.hostname = redis"
  ckan -c "$CONFIG" config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.port = 6379"
  ckan -c "$CONFIG" config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.redis_db = 0"
  #ckan -c "$CONFIG" config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.password = "

  # Rebuild index - should be removed for production
  #ckan -c "$CONFIG" search-index rebuild

  # Configure harvester - first check if already there <- does not work atm
  #ckan -c "$CONFIG" harvester sources
  #lines=`ckan -c "$CONFIG" harvester sources | grep nomad-lab.eu | wc -l`
  #lines=$(($lines + 1))
  #if [ $lines -lt 2 ]; then
  #    ckan -c "$CONFIG" harvester source "nomad" "https://nomad-lab.eu/prod/rae/dcat/catalog/" dcat_rdf "NOMAD DCAT Interface" True tib-iasis MANUAL '{"rdf_format":"application/rdf+xml"}'
      #ckan -c "$CONFIG" harvester source dsms https://dsms.stream-dataspace.net/catalog/ dcat_rdf "DSMS DCAT Interface" True tib-iasis MANUAL '{"rdf_format":"text/turtle"}'
  #fi
fi

#Start services for harvesting
env > /etc/ckan/.env
service supervisor start && supervisorctl reread
cron

echo "Ready"

exec "$@"
