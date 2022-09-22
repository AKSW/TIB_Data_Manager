FROM ckan_base

#Install supervisor for harvest jobs
USER root
RUN apt-get update && apt-get install -y supervisor
RUN mkdir -p /var/log/ckan/std/ && chmod 777 -R /var/log/ckan/std/
COPY docker/ckan_harvesting.conf /etc/supervisor/conf.d/ckan_harvesting.conf
RUN touch /var/log/supervisor/supervisord.log && chmod 777 /var/log/supervisor/supervisord.log

#Install cron
RUN apt-get install -y cron git && apt-get -q clean
COPY ./docker/cronfile /etc/cron.d/cronfile
# Give execution rights on the cron job
RUN chmod 0777 /etc/cron.d/cronfile
# Apply cron job
RUN crontab /etc/cron.d/cronfile
# Create the log file to be able to run tail
RUN touch /var/log/cron.log && chmod 777 /var/log/cron.log

#USER ckan

ADD ./Plugins/ckanext-harvest $CKAN_HOME/src/ckanext-harvest
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-harvest
RUN ckan-pip install -r $CKAN_HOME/src/ckanext-harvest/pip-requirements.txt

ADD ./Plugins/ckanext-dcat $CKAN_HOME/src/ckanext-dcat
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-dcat
RUN ckan-pip install -r $CKAN_HOME/src/ckanext-dcat/requirements.txt

ADD ./Plugins/ckanext-streamtheme $CKAN_HOME/src/ckanext-streamtheme
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-streamtheme

# dataretrieval for workshop
ADD ./Plugins/ckanext-dataretrieval $CKAN_HOME/src/ckanext-dataretrieval
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-dataretrieval
RUN ckan-pip install -r $CKAN_HOME/src/ckanext-dataretrieval/requirements.txt

# Not ready
#ADD ./Plugins/ckanext-qualityreports $CKAN_HOME/src/ckanext-qualityreports
#RUN ckan-pip install -e $CKAN_HOME/src/ckanext-qualityreports
#RUN ckan-pip install -r $CKAN_HOME/src/ckanext-qualityreports/requirements.txt

# Not ready
#ADD ./Plugins/ckanext-tags $CKAN_HOME/src/ckanext-tags
#RUN ckan-pip install -e $CKAN_HOME/src/ckanext-tags
#ckan-pip install -r $CKAN_HOME/src/ckanext-tags/requirements.txt

COPY ./docker/ckan-entrypoint.sh /
RUN chmod +x /ckan-entrypoint.sh
