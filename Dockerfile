FROM golang:1.9-alpine as confd
# for Alpine confd we need to build
ARG CONFD_VERSION=0.16.0
ADD https://github.com/kelseyhightower/confd/archive/v${CONFD_VERSION}.tar.gz /tmp/

RUN apk add --no-cache \
    bzip2 \
    make && \
    mkdir -p /go/src/github.com/kelseyhightower/confd && \
    cd /go/src/github.com/kelseyhightower/confd && \
    tar --strip-components=1 -zxf /tmp/v${CONFD_VERSION}.tar.gz && \
    go install github.com/kelseyhightower/confd && \
    rm -rf /tmp/v${CONFD_VERSION}.tar.gz



FROM alpine:3.13.1

LABEL maintainer="gituser <gituser@raizmedia.co.uk>" \
    architecture="amd64/x86_64" \
    nginx-version="1.18.0" \
    alpine-version="3.13.1" \
    build="23-Feb-2021" \
    org.opencontainers.image.title="alpine-nginx" \
    org.opencontainers.image.description="Nginx PHP 7.4 running on Alpine Linux" \
    org.opencontainers.image.authors="nigel <nigel@raizmedia.co.uk>" \
    org.opencontainers.image.vendor="Raiz Systems" \
    org.opencontainers.image.version="v1.0.5" \
    org.opencontainers.image.url="https://hub.docker.com/repository/docker/raiz/nginx-php-fpm-alpine" \
    org.opencontainers.image.source="https://hub.docker.com/repository/docker/raiz/nginx-php-fpm-alpine" 
   

# http://dl-cdn.alpinelinux.org/alpine/v3.12/community/x86_64/
RUN apk --update add \
    php7 \
    php7-pecl-apcu \
    php7-pecl-ast \    
    php7-bcmath \
    #php7-dom \
    #php7-ctype \
    php7-curl \
    #php7-fileinfo \
    php7-fpm \
    #php7-gettext \
    php7-gd \
    php7-iconv \
    php7-intl \
    php7-json \
    php7-mbstring \
    #php7-mcrypt \
    php7-mysqlnd \
    php7-opcache \
    php7-openssl \
    #php7-pdo \
    #php7-pdo_mysql \
    #php7-pdo_pgsql \
    #php7-pdo_sqlite \
    php7-phar \
    #php7-posix \
    #php7-simplexml \
    #php7-session \
    #php7-soap \
    php7-sqlite3 \
    #php7-tokenizer \
    php7-xml \
    #php7-xmlreader \
    #php7-xmlwriter \
    php7-zip \
    && rm -rf /var/cache/apk/*
RUN mkdir -p /etc/php7/pool.d
RUN mkdir -p /run/php


#COPY docker/config/nginx.conf /etc/nginx/nginx.conf
RUN apk add --no-cache nginx libpng composer;     
RUN echo "daemon off;" >> /etc/nginx/nginx.conf


# Add wait-for-it. The Apline version
COPY ./wait-for-it-alpine.sh /bin/wait-for-it.sh
RUN chmod 755 /bin/wait-for-it.sh

# Install confd
COPY --from=confd /go/bin/confd /bin/confd
RUN chmod +x /bin/confd
# Add confd configs
COPY /confd/ /etc/confd/

# Add S6 supervisor (for graceful stop)
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /
ENTRYPOINT ["/init"]
CMD []

# https://superuser.com/questions/1306656/cant-run-nginx-in-alpine-linux-docker
RUN mkdir -p /run/nginx

COPY ./02-confd-onetime /etc/cont-init.d/02-confd-onetime
RUN chmod 755 /etc/cont-init.d/02-confd-onetime

# Copy NGINX service script
COPY ./services/start-nginx.sh /etc/services.d/nginx/run
RUN chmod 755 /etc/services.d/nginx/run

# Copy PHP-FPM service script
COPY ./services/start-fpm.sh /etc/services.d/php_fpm/run
RUN chmod 755 /etc/services.d/php_fpm/run