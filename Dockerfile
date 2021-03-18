
FROM ckan_base
MAINTAINER Gabriel Gimenez @ Fraunhofer

# SetUp custom plugin
ADD ./Plugins/ckanext-videoviewer $CKAN_HOME/src/ckanext-videoviewer
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-videoviewer

ADD ./Plugins/ckanext-TIBtheme $CKAN_HOME/src/ckanext-TIBtheme
RUN ckan-pip install -e $CKAN_HOME/src/ckanext-TIBtheme

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

COPY ./docker/ckan-entrypoint.sh /
RUN chmod +x /ckan-entrypoint.sh
