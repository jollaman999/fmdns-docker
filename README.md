# facileManager-docker

This project is not affiliated with WillyXJ/facileManager or facileManager.com. This is an entirely independent project to dockerize the service.

## Automation Quick start
* Configure variables in `init_fmDNS.sh` script file.
```
FM_SERVER_IP="10.0.0.1"
FM_SERVER_PORT="5081"
FM_USERNAME="admin"
FM_PASSWORD="fmAdmin1234!@#$"
FM_USEREMAIL="admin@jollaman999.com"

FACILE_CLIENT_SERIAL_NUMBER="20240404"

DOMAIN_NAME="test.com"
SUB_DOMAIN_A_RECORD="sub"
SUB_DOMAIN_A_RECORD_IP="172.16.0.100"

ENABLE_EXTERNAL_NAMESERVERS="false"
# EXTERNAL_NAMESERVER_1="1.1.1.1"
# EXTERNAL_NAMESERVER_2="1.0.0.1"
```

* Start and initialize DNS server with the specified domain in `init_fmDNS.sh` script file.
```
./init_fmDNS.sh
```

* Setting your DNS server from client.
```
Primary: {FM_SERVER_IP}
Secondary: 1.1.1.1
```

* Check if your domain is working.
```
> dig sub.test.com

; <<>> DiG 9.11.9 <<>> sub.test.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 24009
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 4776669b7772980d01000000660e818f13ba889d02a2015f (good)
;; QUESTION SECTION:
;sub.test.com.            IN      A

;; ANSWER SECTION:
sub.test.com.     86400   IN      A       172.16.0.100

;; Query time: 0 msec
;; SERVER: 10.0.0.1#53(10.0.0.1)
;; WHEN: Thu Apr 04 19:31:43     2024
;; MSG SIZE  rcvd: 91
```

## facileManager Server

### Environment Flags
* MYSQL_HOST = Hostnane of MySQL server or container
* MYSQL_DATABASE = MySQL database name for FM to use
* MYSQL_USER = MySQL username for FM to login with
* MYSQL_PASSWORD = MySQL password for FM to login with
* TZ = Timezone for more readable logs 			default UTC	# optional


## fmDNS Client

### Environment Flags
* FACILE_MANAGER_HOST = Hostnane of fM server or container	default localhost
* FACILE_CLIENT_SERIAL_NUMBER = Client serial number		default random number between 100000000 & 999999999
* 	Without this, the client will reinstall every reboot and service could be inconsistant
* FACILE_MANAGER_AUTHKEY = facileManager authkey		default "default"
* FACILE_CLIENT_LOG_FILE = Path to log file					# optional
* 	If you have a log file configured in Bind/fM, set this or else Bind will fail to start
* TZ = Timezone for more readable logs 				default UTC	# optional

## Notes

* fMDNS client logs will show bind logs by default. To show all DNS requests in these logs add `querylog = yes` to Config -> Options in fM server.
* In some situations, reverse proxies can prevent the server from upgrading or recognizing a rebooting/reinstalling client. The fix is to add a macvlan/ipvlan network and IP to your fM server container to connect to directly. Ex.:
```
docker network create \
	-d macvlan \
	--subnet=192.168.0.0/24 \
	--gateway=192.168.0.1 \
	-o parent=eth0 \
	--ip-range 192.168.2.240/29 \
	macvlan
docker network connect \
	macvlan --ip 192.168.0.10 fM
```
* Some Linux distros ship with systemd-resolved which binds to port 53. There are two solutions to this:
* 	Follow [these steps](https://www.linuxuprising.com/2020/07/ubuntu-how-to-free-up-port-53-used-by.html) to unbind the service for fmDNS.
* 	Use a macvlan/ipvlan so the client listens on a different IP than the host. With this fix, the host won't be able to easily use the container for DNS.
