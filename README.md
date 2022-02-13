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

## Running FM Container

```
docker run -d \
	--name FM \
	-e MYSQL_HOST=MySQL_FM. \
	-e MYSQL_DATABASE=facileManager \
	-e MYSQL_USER=facileManager \
	-e MYSQL_PASSWORD=<password> \
	mecjay12/fm
```

## Notes
* If you are considering adding a DNS container as well:
	* Docker has a current bug where publishing port 53 without an IP binding will prevent Docker nodes from doing DNS lookups. Hostip bindings are not availible in Swarms.
	* Docker Swarm is missing features that allow for static IPs on a container/service/task.
