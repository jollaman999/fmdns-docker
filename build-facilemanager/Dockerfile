FROM php:7.4-apache

ENV Version=4.2.0
WORKDIR /src

RUN	apt-get update \
	&& apt-get -qqy install wget libldb-dev libldap2-dev ssh \
	&& wget http://www.facilemanager.com/download/facilemanager-complete-4.2.0.tar.gz \
	&& tar -xvf facilemanager-complete*.tar.gz \
	&& mv facileManager/server/* /var/www/html/ \
	&& mkdir /fm_dns/ \
	&& chown -R www-data:www-data /fm_dns/ \
	&& rm -rf /var/lib/apt/lists/* \
    && chown -R www-data:www-data /var/www/html/

RUN ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
	&& docker-php-ext-install mysqli ldap \
	&& a2enmod rewrite dump_io

COPY config.inc.php /var/www/html/
COPY php.ini /usr/local/etc/php/php.ini
COPY init.php.patch /var/www/html/fm-includes/

RUN patch /var/www/html/fm-includes/init.php /var/www/html/fm-includes/init.php.patch
