
FROM ckan_base
MAINTAINER Gabriel Gimenez @ Fraunhofer

# SetUp custom plugin
ADD ./Plugins/ckanext-videoviewer $CKAN_HOME/src/ckanext-videoviewer
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-videoviewer

ADD ./Plugins/ckanext-streamtheme $CKAN_HOME/src/ckanext-streamtheme
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-streamtheme

ADD ./Plugins/ckanext-harvest $CKAN_HOME/src/ckanext-harvest
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-harvest
RUN ckan-pip install -r $CKAN_HOME/src/ckanext-harvest/pip-requirements.txt

ADD ./Plugins/ckanext-dcat $CKAN_HOME/src/ckanext-dcat
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-dcat
RUN ckan-pip install -r $CKAN_HOME/src/ckanext-dcat/requirements.txt

#DEBUG
ADD ./Plugins/ckanext-dataretrieval $CKAN_HOME/src/ckanext-dataretrieval
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-dataretrieval
RUN ckan-pip install -r $CKAN_HOME/src/ckanext-dataretrieval/requirements.txt

#Install supervisor for harvest jobs
RUN apt-get update && apt-get install -y supervisor
RUN mkdir -p /var/log/ckan/std/
COPY docker/ckan_harvesting.conf /etc/supervisor/conf.d/ckan_harvesting.conf

#Install cron
RUN apt-get install -y cron
COPY ./docker/cronfile /etc/cron.d/cronfile
# Give execution rights on the cron job
RUN chmod 0744 /etc/cron.d/cronfile
# Apply cron job
RUN crontab /etc/cron.d/cronfile
# Create the log file to be able to run tail
RUN touch /var/log/cron.log

COPY ./docker/ckan-entrypoint.sh /
RUN chmod +x /ckan-entrypoint.sh
