#!/bin/sh
set -e

CONFIG="${CKAN_CONFIG}/ckan.ini"
TIMER=5

set_environment () {
  export CKAN_SQLALCHEMY_URL=${CKAN_SQLALCHEMY_URL}
  export CKAN_SOLR_URL=${CKAN_SOLR_URL}
  export CKAN_REDIS_URL=${CKAN_REDIS_URL}
  export CKAN_STORAGE_PATH=${CKAN_STORAGE_PATH}
  export CKAN_SITE_URL=${CKAN_SITE_URL}
}

# Note that this only gets called if there is no config, see below!
write_config () {
  ckan-paster make-config --no-interactive ckan "$CONFIG"

  ckan-paster --plugin=ckan config-tool "$CONFIG" -s DEFAULT -e "debug = true"
  # The variables above will be used by CKAN, but
  # in case want to use the config from ckan.ini use this
  ckan-paster --plugin=ckan config-tool "$CONFIG" -e \
     "sqlalchemy.url = ${CKAN_SQLALCHEMY_URL}" \
     "solr_url = ${CKAN_SOLR_URL}" \
     "ckan.redis.url = ${CKAN_REDIS_URL}" \
     "ckan.storage_path = ${CKAN_STORAGE_PATH}" \
     "ckan.site_url = ${CKAN_SITE_URL}" \
     "ckan.datapusher.url = ${CKAN_PUSHER_URL}" \
     "ckan.datastore.write_url = ${CKAN_DATASTORE_WRITE}" \
     "ckan.datastore.read_url = ${CKAN_DATASTORE_READ}" \
     "smtp.server = postfix" \
     "ckan.views.default_views = image_view text_view recline_view videoviewer" \
     "smtp.mail_from = admin@datahub.com" \
     "ckan.plugins = stats text_view image_view recline_view resource_proxy datastore datapusher webpage_view videoviewer STREAMtheme" \
     "ckan.datapusher.formats = csv xls xlsx tsv application/csv application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" \
     "ckan.max_resource_size = 104857600"
}

set_environment

# We are not waiting until the database is ready.
# This could be improved.
# wait for postgres db to be available, immediately after creation
# its entrypoint creates the cluster and dbs and this can take a moment 

# If we don't already have a config file, bootstrap
if [ ! -e "$CONFIG" ]; then
  write_config

  # Initializes the Database
  ckan-paster --plugin=ckan db init -c "${CKAN_CONFIG}/ckan.ini"
  
  # Enable Plugins: harvest and dcat
  ckan-paster --plugin=ckan config-tool "$CONFIG" -e \
     "ckan.plugins = stats text_view image_view recline_view resource_proxy datastore datapusher webpage_view videoviewer harvest ckan_harvester dcat dcat_json_interface dcat_rdf_harvester dcat_json_harvester structured_data STREAMtheme dataretrieval"
  ckan-paster --plugin=ckanext-harvest harvester initdb --config=$CKAN_CONFIG/ckan.ini
  ckan-paster --plugin=ckan config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.type = redis"
  ckan-paster --plugin=ckan config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.hostname = redis"
  ckan-paster --plugin=ckan config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.port = 6379"
  ckan-paster --plugin=ckan config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.redis_db = 0"
  #ckan-paster --plugin=ckan config-tool "$CONFIG" -s "app:main" "ckan.harvest.mq.password = "

  # Rebuild index 
  ckan-paster --plugin=ckan search-index rebuild -c $CKAN_CONFIG/ckan.ini

  # Configure harvester
  ckan-paster --plugin=ckanext-harvest harvester source nomad https://nomad-lab.eu/prod/rae/dcat/catalog/ dcat_rdf "NOMAD DCAT Interface" True tib-iasis MANUAL '{"rdf_format":"application/rdf+xml"}' --config=/etc/ckan/default/ckan.ini
  #ckan-paster --plugin=ckanext-harvest harvester source dsms https://dsms.eu/prod/rae/dcat/catalog/ dcat_rdf "DSMS DCAT Interface" True tib-iasis MANUAL '{"rdf_format":"application/rdf+xml"}' --config=/etc/ckan/default/ckan.ini
fi

echo "Ready"

exec "$@"
