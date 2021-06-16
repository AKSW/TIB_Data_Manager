FROM ckan/solr



#ENV CKAN_VERSION 2.7.0
#RUN curl https://raw.githubusercontent.com/ckan/ckan/ckan-$CKAN_VERSION/ckan/config/solr/schema.xml > /schema.xml
RUN mkdir -p /opt/solr/example/solr/ckan/conf/
#RUN mv /schema.xml /opt/solr/server/solr/ckan/conf/schema.xml
ADD schema.xml /opt/solr/server/solr/ckan/conf/schema.xml
ADD solrconfig.xml /opt/solr/server/solr/ckan/conf/solrconfig.xml
