FROM php:5-apache

WORKDIR /src

RUN	apt-get update \
	&& apt-get -qqy install wget libldb-dev libldap2-dev \
	&& wget http://www.facilemanager.com/download/facilemanager-complete-4.2.0.tar.gz \
	&& tar -xvf facilemanager-complete*.tar.gz \
	&& mv facileManager/server/* /var/www/html/ \
    && chown -R www-data:www-data /var/www/html/

RUN ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
	&& docker-php-ext-install mysql mysqli ldap \
	&& a2enmod rewrite dump_io

COPY build-facilemanager/config.inc.php /var/www/html/
COPY build-facilemanager/php.ini /usr/local/etc/php/php.ini
COPY build-facilemanager/init.php.patch /var/www/html/fm-includes/

RUN patch /var/www/html/fm-includes/init.php /var/www/html/fm-includes/init.php.patch
