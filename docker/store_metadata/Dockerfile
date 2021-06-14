FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y git pigz pbzip2 virtuoso-opensource raptor2-utils openjdk-11-jdk jq wget curl
RUN wget https://github.com/SmartDataAnalytics/RdfProcessingToolkit/releases/download/rdf-processing-toolkit-bundle-1.1.0-SNAPSHOT/rdf-processing-toolkit-bundle-1.1.0-SNAPSHOT-jar-with-dependencies.jar
RUN mv rdf-processing-toolkit-bundle-1.1.0-SNAPSHOT-jar-with-dependencies.jar /rdf-processing-toolkit.jar
RUN mkdir /virtuoso
RUN mkdir /virtuoso/metadataimport
RUN mkdir /root/.ssh && ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts && chmod 0644 /root/.ssh

# Add files
ADD download_NOMAD.sh /virtuoso/metadataimport/download_NOMAD.sh
ADD import.sh /virtuoso/metadataimport/import.sh
ADD envsetter.sh /virtuoso/metadataimport
RUN chmod 0744 /virtuoso/metadataimport/envsetter.sh

WORKDIR /virtuoso/metadataimport

# Run the command on container startup
CMD ["/virtuoso/metadataimport/envsetter.sh"]
