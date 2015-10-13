FROM php:5.6-apache

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y php5-mysql mysql-client emacs24-nox vim git curl \
    && docker-php-ext-install mysql

RUN ln -s /root/wp /var/www/html/
WORKDIR /root
