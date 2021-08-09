FROM nuxeo/nuxeo:latest

ENV NUXEO_HOME=/opt/nuxeo/server

USER 0

# install RPM Fusion free repository
RUN yum -y localinstall --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
# install ffmpeg package
RUN yum -y install ffmpeg
# install nc command for wait-for.sh
RUN yum -y install nc
# install wget command for wait-for.sh
RUN yum -y install wget
# set back original user
USER 900

COPY --chown=900:0 nuxeo-showcase-content-2021.0.2.zip $NUXEO_HOME/local-packages/nuxeo-showcase-content-2021.0.2.zip
COPY --chown=900:0 nuxeo-web-ui-marketplace-3.1.0-SNAPSHOT.zip $NUXEO_HOME/local-packages/nuxeo-web-ui-marketplace-3.1.0-SNAPSHOT.zip

# Install a local package without its dependencies (`mp-install --nodeps`)
RUN /install-packages.sh --offline $NUXEO_HOME/local-packages/nuxeo-showcase-content-2021.0.2.zip
RUN /install-packages.sh --offline $NUXEO_HOME/local-packages/nuxeo-web-ui-marketplace-3.1.0-SNAPSHOT.zip

# Install remote packages and a local package with its dependencies
RUN rm -rf $NUXEO_HOME/local-packages

# COPY wait-for
COPY --chown=900:0 wait-for.sh /
RUN chmod +x /wait-for.sh

EXPOSE 8080
ENTRYPOINT /wait-for.sh mysql:3306 -t 300 && /wait-for.sh elasticsearch:9200 -t 300 && /docker-entrypoint.sh nuxeoctl console