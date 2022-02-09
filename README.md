# fmDNS-docker

## Goal

The main goal of this project is to easy the entry of using fmDNS and to provide an option that uses docker.

Secondary Goals:
* The both the facileManager container and the fmDNS container should be stateless. Date should only be kept in MySQL
* Rebuilding a fmDNS container should reconnect to facileManager without user intervention and not create a duplicate

## Environment Flags
* MYSQL_HOST = Hostnane of MySQL server or container
* MYSQL_DATABASE = MySQL database name for FM to use
* MYSQL_USER = MySQL username for FM to login with
* MYSQL_PASSWORD = MySQL password for FM to login with
* fm_URL = This is the external URL you plan to use to access the web management interface
* fmDNS_Manager = The DNS name of the facileManager that fmDNS should use to find facileManager
* fmDNS_Serial = The serial number for this instance of fmDNS. This needs to be unique on each instance

## Pre-Requirments
You must have a MySQL database ready for FM manager to connect to. If you do not, run the following for the simplest setup:

```
docker run -d \
	--name MySQL_FM \
	--mount type=bind,src=/path/to/persistant/storage,dst=/var/lib/mysql \
	-e MYSQL_ROOT_PASSWORD=<password> \
	-e MYSQL_DATABASE=facileManager \
	-e MYSQL_USER=facileManager \
	-e MYSQL_PASSWORD=<password> \
	mysql/mysql-server
```

## Running Manager Container

```
docker run -d \
	--name FM \
	-e MYSQL_HOST=MySQL_FM. \
	-e MYSQL_DATABASE=facileManager \
	-e MYSQL_USER=facileManager \
	-e MYSQL_PASSWORD=<password> \
	mecjay12/fm
```

## Running DNS Container
Note: I haven't tested this yet, YMMV. Must be built by hand from inside the build-fmDNS directory.

```
docker build -t fmDNS .
docker run -d \
	--name DNS \
	-p 53:53 \
	-p 53:53/udp \
	-e FACILE_MANAGER_HOST=<FM container hostname> \
	-e FACILE_CLIENT_SERIAL_NUMBER=<serial number> \
```

## Notes
* Within ~1 minute of finishing the setup the DNS client should join the server.
    * If the server does not show up run the following command: ```docker exec -it fmDNS-bind9 /entrypoint.sh``` replacing fmDNS-bind9 with your container name.