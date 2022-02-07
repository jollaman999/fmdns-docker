FROM php:5-apache

WORKDIR /src

RUN	apt-get update \
	&& apt-get -qqy install wget bind9 bind9utils dnsutils sudo \
	&& wget http://www.facilemanager.com/download/facilemanager-complete-4.2.0.tar.gz \
	&& tar -xvf facilemanager-complete*.tar.gz \
	&& mv facileManager/client/facileManager /usr/local \
	&& ln -s /usr/local/facileManager/www /var/www/html/fM

COPY build-fmdns/config.inc.php /usr/local/facileManager/
COPY build-fmdns/entrypoint.sh /
COPY build-fmdns/php.ini /usr/local/etc/php/

RUN mkdir /var/log/bind \
    && chown bind:bind /var/log/bind

ENV FACILE_MANAGER_HOST=localhost/
ENV FACILE_MANAGER_AUTHKEY=default
ENV FACILE_CLIENT_SERIAL_NUMBER=

CMD ["apache2-foreground"]
ENTRYPOINT ["/entrypoint.sh"]
