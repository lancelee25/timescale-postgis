#ARG PG_VERSION_TAG=pg11
#ENV TS_VERSION ${TS_VERSION:-1.5.1}
#FROM timescale/timescaledb:${TS_VERSION}-${PG_VERSION_TAG}
FROM timescale/timescaledb:1.5.1-pg11
#ARG PG_VERSION_TAG
#FROM timescale/timescaledb:1.5.1-${PG_VERSION_TAG}

MAINTAINER Timescale https://www.timescale.com
ARG POSTGIS_VERSION
ENV POSTGIS_VERSION ${POSTGIS_VERSION:-3.0.0}
#COPY postgis-${POSTGIS_VERSION}.tar.gz /tmp

RUN set -ex \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >/etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                openssl \
                tar \
    # add libcrypto from (edge:main) for gdal-2.3.0
    && apk add --no-cache --virtual .crypto-rundeps --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
                libressl3.0-libcrypto \
                libcrypto1.1 \
    && apk add --no-cache --virtual .postgis-deps --repository http://dl-cdn.alpinelinux.org/alpine/edge/community  \
        geos \
        gdal \
        proj \
        protobuf-c \
    && apk add --no-cache --virtual .build-deps --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
        postgresql-dev \
        perl \
        file \
        geos-dev \
        libxml2-dev \
        gdal-dev \
        proj-dev \
        protobuf-c-dev \
        json-c-dev \
        gcc g++ \
        make libstdc++\
    && cd /tmp \
    && wget https://git.osgeo.org/gitea/postgis/postgis/archive/3.0.0.tar.gz -O -|tar -zx \
    #&& tar -zxvf postgis-${POSTGIS_VERSION}.tar.gz \
    && chown root:root -R postgis-${POSTGIS_VERSION} \
    && cd /tmp/postgis-${POSTGIS_VERSION} \
    && LDFLAGS=-lstdc++ ./configure \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis/Makefile \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis_topology/Makefile \
    && make -s \
    && make -s install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && cd / \
    \
    && rm -rf /tmp/postgis-${POSTGIS_VERSION}* \
    && apk del .fetch-deps .build-deps
