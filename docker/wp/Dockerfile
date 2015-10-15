FROM php:5.6-apache

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y php5-mysql mysql-client emacs24-nox vim git curl \
    && docker-php-ext-install mysql

COPY 000-default.conf /etc/apache2/sites-available/

RUN a2enmod rewrite
RUN a2ensite 000-default

WORKDIR /root
