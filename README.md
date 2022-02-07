# fmDNS-docker

1. Clone repo with ```git clone https://github.com/Mr-Mors/fmDNS-docker.git```

1. Edit and update ```.env```

1. Build and Start Docker: ```docker-compose up --build```

1. Complete initial log in and install *fmDNS*

1. Within ~1 minute of finishing the setup the DNS client should joing the server.
    * If the server does not show up run the following command: ```docker exec -it fmDNS-bind9 /entrypoint.sh```
