FROM debian:jessie
MAINTAINER Gabriel Gimenez @ Fraunhofer

RUN apt-get -q -y update && apt-get -q -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
		python-dev \
        python-pip \
        python-virtualenv \
	python-wheel \
        python3-dev \
        python3-pip \
        python3-virtualenv \
        python3-wheel \
        libpq-dev \
	libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        postgresql-client \
        build-essential \
        git-core \
	vim \
        wget \
	&& apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

ENV CKAN_HOME /usr/lib/ckan/default
ENV CKAN_CONFIG /etc/ckan/default
ENV CKAN_STORAGE_PATH /var/lib/ckan
ENV CKAN_VERSION ckan-2.7.0

# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# SetUp Virtual Environment CKAN
RUN mkdir -p $CKAN_HOME $CKAN_CONFIG $CKAN_STORAGE_PATH
RUN virtualenv $CKAN_HOME
RUN ln -s $CKAN_HOME/bin/pip /usr/local/bin/ckan-pip
RUN ln -s $CKAN_HOME/bin/paster /usr/local/bin/ckan-paster

# Dowload CKAN Version
RUN git clone --branch $CKAN_VERSION --depth 1 https://github.com/ckan/ckan.git $CKAN_HOME/src/ckan

# SetUp Requirements
RUN ckan-pip install -U pip
RUN ckan-pip install --upgrade -r $CKAN_HOME/src/ckan/requirement-setuptools.txt
# ADD ./ckan/requirements.txt $CKAN_HOME/src/ckan/requirements.txt
RUN ckan-pip install --upgrade -r $CKAN_HOME/src/ckan/requirements.txt

RUN apt-get install -y build-essential libssl-dev libffi-dev python-dev

# TMP-BUGFIX https://github.com/ckan/ckan/issues/3388
# ADD ./ckan/dev-requirements.txt $CKAN_HOME/src/ckan/dev-requirements.txt
# RUN ckan-pip install --upgrade -r $CKAN_HOME/src/ckan/dev-requirements.txt

# TMP-BUGFIX https://github.com/ckan/ckan/issues/3594
RUN ckan-pip install --upgrade urllib3

# BUGFIX TRUNCATE
RUN ckan-pip install Jinja2==2.8 	

# SetUp CKAN
# RUN ckan-pip install -e $CKAN_HOME/src/ckan/
RUN ln -s $CKAN_HOME/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini

# SetUp EntryPoint
COPY ./ckan-entrypoint.sh /
RUN chmod +x /ckan-entrypoint.sh
ENTRYPOINT ["/ckan-entrypoint.sh"]

# Volumes
VOLUME ["/etc/ckan/default"]
VOLUME ["/var/lib/ckan"]
EXPOSE 5000
CMD ["ckan-paster","serve","--reload","/etc/ckan/default/ckan.ini"]

