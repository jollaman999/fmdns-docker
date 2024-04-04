FROM mariadb:11.3.2-jammy

RUN sed -i 's@archive.ubuntu.com@mirror.kakao.com@g' /etc/apt/sources.list

RUN	apt-get update \
	&& apt-get -qqy install telnet
