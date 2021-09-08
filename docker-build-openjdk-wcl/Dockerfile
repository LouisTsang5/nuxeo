# vim:set ft=dockerfile:
FROM       wcl/nuxeo-ubuntu
MAINTAINER WCL <support@wclsolution.com>

ENV NUXEO_USER nuxeo
ENV NUXEO_HOME /opt/nuxeo/server
ENV HOME /opt/nuxeo/server
ENV NUXEO_LOG /var/log/nuxeo
ARG NUXEO_VERSION=master
#ARG NUXEO_DIST_URL=http://community.nuxeo.com/static/latest-snapshot/nuxeo-server-tomcat,SNAPSHOT.zip
ARG NUXEO_MD5=noMD5check

# Create Nuxeo user
RUN useradd -m -d /home/$NUXEO_USER -u 1000 -s /bin/bash $NUXEO_USER

COPY target/distrib/nuxeo-server-tomcat-*.zip /tmp/nuxeo-distribution-tomcat.zip

# Add distribution
RUN if [ $NUXEO_VERSION != "master" ]; then echo "$NUXEO_MD5 /tmp/nuxeo-distribution-tomcat.zip" | md5sum -c -; fi \
    && mkdir -p /tmp/nuxeo-distribution $(dirname $NUXEO_HOME) \
    && unzip -q -d /tmp/nuxeo-distribution /tmp/nuxeo-distribution-tomcat.zip \
    && DISTDIR=$(/bin/ls /tmp/nuxeo-distribution | head -n 1) \
    && mv /tmp/nuxeo-distribution/$DISTDIR $NUXEO_HOME \
    && sed -i -e "s/^org.nuxeo.distribution.package.*/org.nuxeo.distribution.package=docker/" $NUXEO_HOME/templates/common/config/distribution.properties \
    && rm -rf /tmp/nuxeo-distribution* \
    && chmod +x $NUXEO_HOME/bin/*ctl $NUXEO_HOME/bin/*.sh \
    # For arbitrary user in the admin group
    && chmod g+rwX $NUXEO_HOME/bin/*ctl $NUXEO_HOME/bin/*.sh \
    && chown -R 1000:0 $NUXEO_HOME && chmod -R g+rwX $NUXEO_HOME

COPY docker-template $NUXEO_HOME/templates/docker
COPY nuxeo.conf /etc/nuxeo/nuxeo.conf.template
ENV NUXEO_CONF /etc/nuxeo/nuxeo.conf

# Protecting writeable directories to support arbitrary User IDs for OpenShift
# https://docs.openshift.com/container-platform/3.4/creating_images/guidelines.html
RUN chown -R 1000:0 /etc/nuxeo && chmod g+rwX /etc/nuxeo && rm -f $NUXEO_HOME/bin/nuxeo.conf \
    && mkdir -p /var/lib/nuxeo/data \
    && chown -R 1000:0 /var/lib/nuxeo/data && chmod -R g+rwX /var/lib/nuxeo/data \
    && mkdir -p /var/log/nuxeo \
    && chown -R 1000:0 /var/log/nuxeo && chmod -R g+rwX /var/log/nuxeo \
    && mkdir -p /var/run/nuxeo \
    && chown -R 1000:0 /var/run/nuxeo && chmod -R g+rwX /var/run/nuxeo \
    && mkdir -p /docker-entrypoint-initnuxeo.d \
    && chown -R 1000:0 /docker-entrypoint-initnuxeo.d && chmod -R g+rwX /docker-entrypoint-initnuxeo.d  \
    && chmod g=u /etc/passwd

ENV PATH $NUXEO_HOME/bin:$PATH

# COPY wait-for
COPY --chown=1000:0 wait-for.sh /
RUN chmod +x /wait-for.sh

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

COPY --chown=1000:0 local-package/nuxeo-showcase-content-2021.0.2.zip $NUXEO_HOME/local-packages/nuxeo-showcase-content-2021.0.2.zip
COPY --chown=1000:0 local-package/nuxeo-web-ui-marketplace-3.1.0-SNAPSHOT.zip $NUXEO_HOME/local-packages/nuxeo-web-ui-marketplace-3.1.0-SNAPSHOT.zip
COPY --chown=1000:0 local-package/nuxeo-document-type-sample1.zip $NUXEO_HOME/local-packages/nuxeo-document-type-sample1.zip
COPY --chown=1000:0 local-package/nuxeo-document-type-sample2.zip $NUXEO_HOME/local-packages/nuxeo-document-type-sample2.zip
COPY --chown=1000:0 local-package/nuxeo-easyshare-package-11.5-SNAPSHOT.zip $NUXEO_HOME/local-packages/nuxeo-easyshare-package-11.5-SNAPSHOT.zip

USER 1000
RUN cat /etc/nuxeo/nuxeo.conf.template > $NUXEO_CONF
RUN echo "nuxeo.log.dir=$NUXEO_LOG" >> $NUXEO_CONF
RUN echo "nuxeo.pid.dir=/var/run/nuxeo" >> $NUXEO_CONF
RUN echo "nuxeo.data.dir=/var/lib/nuxeo/data" >> $NUXEO_CONF
RUN $NUXEO_HOME/bin/nuxeoctl mp-install --offline --accept=true $NUXEO_HOME/local-packages/nuxeo-showcase-content-2021.0.2.zip
RUN $NUXEO_HOME/bin/nuxeoctl mp-install --offline --accept=true $NUXEO_HOME/local-packages/nuxeo-web-ui-marketplace-3.1.0-SNAPSHOT.zip
RUN $NUXEO_HOME/bin/nuxeoctl mp-install --offline --accept=true $NUXEO_HOME/local-packages/nuxeo-document-type-sample1.zip
RUN $NUXEO_HOME/bin/nuxeoctl mp-install --offline --accept=true $NUXEO_HOME/local-packages/nuxeo-document-type-sample2.zip
RUN $NUXEO_HOME/bin/nuxeoctl mp-install --offline --accept=true $NUXEO_HOME/local-packages/nuxeo-easyshare-package-11.5-SNAPSHOT.zip
RUN rm -rf $NUXEO_HOME/local-packages
RUN rm $NUXEO_CONF

WORKDIR $NUXEO_HOME
#ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8080
#CMD ["nuxeoctl","console"]
ENTRYPOINT /wait-for.sh mysql:3306 -t 300 && /wait-for.sh elasticsearch:9200 -t 300 && /docker-entrypoint.sh nuxeoctl console