FROM debian:stable-slim

LABEL author="Yulyan Glonti"

ENV PHP_VERSION=7.4

RUN apt-get update && apt-get install -y \
    php${PHP_VERSION}-fpm \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    apache2 \
    apache2-utils \
    && apt-get clean

EXPOSE 80

CMD [“apache2ctl”, “-D”, “FOREGROUND”]
