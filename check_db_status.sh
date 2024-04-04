#!/bin/bash

echo "[*] Waiting for database is up..."
cnt=0
while true
do
   (( cnt = "$cnt" + 1 ))
   DB_STATUS=`echo -e '\x1dclose\x0d' | telnet 127.0.0.1 3306 > /dev/null 2>&1 ; echo $?`
   if [ "$DB_STATUS" = "0" ]; then
      break
   fi
   if [ "$cnt" = "6" ]; then
      echo "[!] Error: Failed to connect to database."
      exit 1;
   fi
   sleep 5
done
