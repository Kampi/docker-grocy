# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.20

ARG BUILD_DATE
ARG VERSION
ARG GROCY_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="alex-phillips, homerr"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    git \
    yarn && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    php83-gd \
    php83-intl \
    php83-ldap \
    php83-pdo \
    php83-pdo_sqlite \
    php83-tokenizer && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php83/php-fpm.d/www.conf && \
  grep -qxF 'clear_env = no' /etc/php83/php-fpm.d/www.conf || echo 'clear_env = no' >> /etc/php83/php-fpm.d/www.conf && \
  echo "**** install grocy ****" && \
  mkdir -p /app/www && \
  if [ -z ${GROCY_RELEASE+x} ]; then \
    GROCY_RELEASE=$(curl -s "https://api.github.com/repos/kampi/grocy/releases/latest" | jq -r .tag_name); \
  fi && \
  curl -o \
    /tmp/grocy.tar.gz -L \
    "https://github.com/kampi/grocy/archive/${GROCY_RELEASE}.tar.gz" && \
  tar xf \
    /tmp/grocy.tar.gz -C \
    /app/www/ --strip-components=1 && \
  cp -R /app/www/data/plugins \
    /defaults/plugins && \
  echo "**** install composer packages ****" && \
  composer install -d /app/www --no-dev && \
  echo "**** install yarn packages ****" && \
  cd /app/www && \
  yarn --production && \
  yarn cache clean && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    $HOME/.cache \
    $HOME/.composer

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME /config
