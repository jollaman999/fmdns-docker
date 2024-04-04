FROM php:8.2-apache

WORKDIR /src

RUN sed -i 's@deb.debian.org@mirror.kakao.com@g' /etc/apt/sources.list.d/debian.sources
RUN sed -i 's@mirror.kakao.com/debian-security@deb.debian.org/debian-security@g' /etc/apt/sources.list.d/debian.sources

ENV	DNS_Version=6.0.3
ENV	Core_Version=4.6.1
RUN	apt-get update \
	&& apt-get -qqy install wget bind9 dnsutils sudo
RUN	wget http://facilemanager.com/download/module/fmdns-$DNS_Version.tar.gz \
	&& wget http://facilemanager.com/download/facilemanager-core-$Core_Version.tar.gz \
	&& tar -xvf fmdns-$DNS_Version.tar.gz \
	&& tar -xvf facilemanager-core-$Core_Version.tar.gz \
	&& mv facileManager/client/facileManager /usr/local \
	&& ln -s /usr/local/facileManager/www /var/www/html/fM

COPY config.inc.php /usr/local/facileManager/
COPY entrypoint.sh /
COPY php.ini /usr/local/etc/php/

ENV FACILE_MANAGER_HOST=localhost/
ENV FACILE_MANAGER_AUTHKEY=default
ENV FACILE_CLIENT_SERIAL_NUMBER=
ENV FACILE_CLIENT_LOG_FILE=

RUN	rm -rf /var/lib/apt/lists/* \
	&& rm -rf /src/facileManager

CMD ["sudo -u bind named -g"]
ENTRYPOINT ["/entrypoint.sh"]
