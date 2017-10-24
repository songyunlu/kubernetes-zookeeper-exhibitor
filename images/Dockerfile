FROM openjdk:8-jdk-alpine

LABEL maintainer="Jimmy Lu <gn00023040@gmail.com>"

# Args for built time overrides
ARG EXHIBITOR_VERSION="1.5.6"
ARG MVN_VERSION="3.3.9"
ARG ZK_VERSION="3.4.11"
ARG GPG_KEY="D0BC8D8A4E90A40AFDFC43B3E22A746A68E327C1"

ENV BUILD_DEPS="ca-certificates gnupg libressl dos2unix" \
    EXHIBITOR_POM="https://raw.githubusercontent.com/Netflix/exhibitor/v$EXHIBITOR_VERSION/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml" \
    MVN_RELEASE="http://www.apache.org/dist/maven/maven-3/$MVN_VERSION/binaries/apache-maven-$MVN_VERSION-bin.tar.gz" \
    ZK_RELEASE="http://www.apache.org/dist/zookeeper/zookeeper-$ZK_VERSION/zookeeper-$ZK_VERSION.tar.gz" \
    ZK_ASC="http://www.apache.org/dist/zookeeper/zookeeper-$ZK_VERSION/zookeeper-$ZK_VERSION.tar.gz.asc" \
    ZK_GPG_KEYS="http://archive.apache.org/dist/zookeeper/KEYS" \
    DI_VERSION=1.2.0 \
    DI_SHA=81231da1cd074fdc81af62789fead8641ef3f24b6b07366a1c34e5b059faf363

# Add the optional web.xml for authentication
ADD files/web.xml /opt/exhibitor/web.xml
# Add the run script to setup configs and exec exhibitor
ADD files/run.sh /opt/exhibitor/run.sh

# Use one step so we can remove intermediate dependencies and minimize size
RUN set -ex \
    # Install required packages
    && apk add --no-cache bash fuse \
    && apk add --no-cache --virtual .build-deps $BUILD_DEPS \
    # Default DNS cache TTL is -1. DNS records, like, change, man.
    && sed -i 's/^#*\(networkaddress.cache.ttl\).*/\1=60/' /usr/lib/jvm/default-jvm/jre/lib/security/java.security \
    # Alpine doesn't have /opt dir
    && mkdir -p /opt \
    # Install ZK
    && wget -q -O /tmp/zookeeper.tgz $ZK_RELEASE \
    && wget -q -O /tmp/zookeeper.tgz.asc $ZK_ASC \
    && wget -q -O /tmp/KEYS $ZK_GPG_KEYS \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --import /tmp/KEYS \
    && gpg --batch --verify "/tmp/zookeeper.tgz.asc" "/tmp/zookeeper.tgz" \
    && tar -xvzf /tmp/zookeeper.tgz -C /opt/ \
    && ln -s /opt/zookeeper-* /opt/zookeeper \
    # Install maven
    && wget -q -O /tmp/apache-maven.tgz $MVN_RELEASE \
    && tar -xvzf /tmp/apache-maven.tgz -C /opt/ \
    && ln -s /opt/apache-maven-* /opt/apache-maven \
    # Install Exhibitor
    && mkdir -p /opt/exhibitor \
    && wget -q -O /opt/exhibitor/pom.xml $EXHIBITOR_POM \
    && /opt/apache-maven/bin/mvn -f /opt/exhibitor/pom.xml package \
    && ln -s /opt/exhibitor/target/exhibitor*jar /opt/exhibitor/exhibitor.jar \
	# Install dumb-init
    && wget -q -O /sbin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DI_VERSION}/dumb-init_${DI_VERSION}_amd64 \
    && echo "$DI_SHA  /sbin/dumb-init" | sha256sum -c - \
    && chmod +x /sbin/dumb-init \
    # Normalize scripts format
    && dos2unix /opt/exhibitor/run.sh \
    # Remove build-time dependencies
    && apk del .build-deps \
    && rm -rf \
          /opt/apache-maven* \
          ~/.m2 \
          /var/cache/apk/* \
          /tmp/*


WORKDIR /opt/exhibitor
EXPOSE 2181 2888 3888 8181

ENTRYPOINT ["/sbin/dumb-init", "bash", "-ex", "/opt/exhibitor/run.sh"]
