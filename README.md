# fmDNS-docker

## Goal

The main goal of this project is to easy the entry of using fmDNS and to provide an option that uses docker.

Secondary Goals:
* The both the facileManager container and the fmDNS container should be stateless. Date should only be kept in MySQL
* Rebuilding a fmDNS container should reconnect to facileManager without user intervention and not create a duplicate

## Setup (facileManager and first fmDNS container)
1. Clone this repo by running: ```git clone https://github.com/Mr-Mors/fmDNS-docker.git```

1. Copy/Rename ```.env.example``` to ```.env```

1. Edit the environments file and update to your needs. Explanation of flags in section below.

1. Build and Start Docker: ```docker-compose up -d --build```

1. Complete initial log in and install *fmDNS*

1. Within ~1 minute of finishing the setup the DNS client should joing the server.
    * If the server does not show up run the following command: ```docker exec -it fmDNS-bind9 /entrypoint.sh```

## Environment flags
* COMPOSE_PROJECT_NAME = Names the project, all containers will have this prepended to their name.
* MYSQL_* = Flags for MySQL Database
* fm_URL = This is the external URL you plan to use to access the web management interface
* fmDNS_URL = This is the DNS name you plan to use for this DNS server. 
* fmDNS_Manager = The DNS name of the facileManager that fmDNS should use to find facileManager. If the containers are in the same docker network, then use “dns”. Otherwise use the FQDN
* fmDNS_Serial = The serial number for this instance of fmDNS. This needs to be unique on each instance.
* fmDNS_External_IP = This is the IP docker will bind and forward to the fmDNS instance for port 53 TCP/UDP

