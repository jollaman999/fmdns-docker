#!/bin/bash

# !! WARNING !!
# The password (FM_PASSWORD) must be at least eight (8) characters long containing uppercase and lowercase letters, numbers, and special characters ('&', '$', '@', etc.).

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

DB_CONTAINER_NAME="jolla_dns_db"
FMDNS_CLIENT_CONTAINER_NAME="jolla_dns_fmdns"

function goto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

end=${1:-"end"}

export RUN_PATH=`dirname $0`
EXIT_CODE="0"

docker compose up -d

# Check DB status
docker cp $RUN_PATH/check_db_status.sh $DB_CONTAINER_NAME:/root/check_db_status.sh
docker exec -it -u 0 $DB_CONTAINER_NAME /bin/sh -c /root/check_db_status.sh
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Please check the database container status!"
  EXIT_CODE="1"
  goto end
fi
docker exec -it -u 0 $DB_CONTAINER_NAME rm /root/check_db_status.sh

echo "[*] Setting fmDNS..."

# Setting FM
curl -s 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/fm-install.php?step=3' > /dev/null

# Wait for database setting
echo "[*] Waiting 10 seconds for database to be set up..."
sleep 10

# Register user
FM_USERNAME_ENCODED=$(echo $FM_USERNAME | sed -f $RUN_PATH/urlencode.sed)
FM_PASSWORD_ENCODED=$(echo $FM_PASSWORD | sed -f $RUN_PATH/urlencode.sed)
FM_USEREMAIL_ENCODED=$(echo $FM_USEREMAIL | sed -f $RUN_PATH/urlencode.sed)
FM_PASSWORD_ENCODED=$(echo $FM_PASSWORD | sed -f $RUN_PATH/urlencode.sed)
curl -s 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/fm-install.php?step=5' \
  --data-raw 'user_login='"$FM_USERNAME_ENCODED"'&user_email='"$FM_USEREMAIL_ENCODED"'&user_password='"$FM_PASSWORD_ENCODED"'&cpassword='"$FM_PASSWORD_ENCODED"'&submit=Submit' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to register user!"
  EXIT_CODE="1"
  goto end
fi

# Login
curl -s --cookie-jar cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/zone-records-write.php' \
  --data-raw 'username='"$FM_USERNAME"'&password='"$FM_PASSWORD"'&is_ajax=1' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to login to FM!"
  EXIT_CODE="1"
  goto end
fi

# Enable fmDNS module
curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/admin-modules.php?action=activate&module=fmDNS' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to enable fmDNS module!"
  EXIT_CODE="1"
  goto end
fi

# Wait for fmDNS setting
echo "[*] Waiting 10 seconds for fmDNS to be set up..."
sleep 10

# Re-login
curl -s --cookie-jar cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/zone-records-write.php' \
  --data-raw 'username='"$FM_USERNAME"'&password='"$FM_PASSWORD"'&is_ajax=1' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to re-login to FM!"
  EXIT_CODE="1"
  goto end
fi

# Get domain id
DOMAIN_ID=`curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/zones-forward.php' | grep "$DOMAIN_NAME" | grep 'tr id' | xargs | tr " " "\n" | grep id | cut -d'=' -f 2`
STATUS=`echo $?`
if [ "$DOMAIN_ID" != "" ] && [ "$STATUS" = "0" ]; then
  # Delete previous created domain
  curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/fm-modules/facileManager/ajax/processPost.php' \
    --data-raw 'item_id='"$DOMAIN_ID"'&item_type=domains&action=delete&is_ajax=1' \
    > curl_output
fi

# Add domain
curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/zones-forward.php' \
  --data-raw 'action=create&domain_id=0&domain_name='"$DOMAIN_NAME"'&domain_template_id=&domain_mapping=forward&domain_type=primary&domain_forward%5B%5D=first&domain_required_servers%5Bforwarders%5D=&domain_required_servers%5Bmasters%5D=&domain_redirect_url=&domain_clone_domain_id=&domain_clone_dname=yes&domain_name_servers%5B%5D=0&domain_ttl=&soa_id=0&domain_dnssec_sig_expire=&domain_dnssec_parent_domain_id=0' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to add domain!"
  EXIT_CODE="1"
  goto end
fi

# Get domain id
DOMAIN_ID=`curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/zones-forward.php' | grep "$DOMAIN_NAME" | grep 'tr id' | xargs | tr " " "\n" | grep id | cut -d'=' -f 2`
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to get domain ID!"
  EXIT_CODE="1"
  goto end
fi

# Add SOA record to domain
curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/zone-records-write.php' \
  --data-raw 'domain_id='"$DOMAIN_ID"'&record_type=SOA&map=forward&uri=%2Fzone-records.php%3Fmap%3Dforward%26domain_id%3D4%26record_type%3DSOA&create%5B0%5D%5Bsoa_master_server%5D=ns.'"$DOMAIN_NAME"'.&create%5B0%5D%5Bsoa_email_address%5D=admin.'"$DOMAIN_NAME"'.&create%5B0%5D%5Bsoa_refresh%5D=2h&create%5B0%5D%5Bsoa_retry%5D=1h&create%5B0%5D%5Bsoa_expire%5D=2w&create%5B0%5D%5Bsoa_ttl%5D=1d&create%5B0%5D%5Bsoa_append%5D=no&create%5B0%5D%5Bsoa_name%5D=&create%5B0%5D%5Bsoa_default%5D=yes&submit=Submit' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to add SOA record to domain!"
  EXIT_CODE="1"
  goto end
fi

# Add NS record to domain
curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/zone-records-write.php' \
  --data-raw 'domain_id='"$DOMAIN_ID"'&record_type=NS&map=forward&uri=%2Fzone-records.php%3Fmap%3Dforward%26domain_id%3D12%26record_type%3DNS&create%5B1%5D%5Brecord_name%5D=%40&create%5B1%5D%5Brecord_ttl%5D=&create%5B1%5D%5Brecord_value%5D=ns&create%5B1%5D%5Brecord_comment%5D=&create%5B1%5D%5Brecord_append%5D=yes&create%5B1%5D%5Brecord_status%5D=active&submit=Submit' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to add NS record to domain!"
  EXIT_CODE="1"
  goto end
fi

# Add NS's A records to domain
curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/zone-records-write.php' \
  --data-raw 'domain_id='"$DOMAIN_ID"'&record_type=A&map=forward&uri=%2Fzone-records.php%3Fmap%3Dforward%26domain_id%3D12%26record_type%3DA&create%5B1%5D%5Brecord_name%5D=ns&create%5B1%5D%5Brecord_ttl%5D=&create%5B1%5D%5Brecord_value%5D='"$FM_SERVER_IP"'&create%5B1%5D%5Brecord_comment%5D=&create%5B1%5D%5Brecord_status%5D=active&create%5B2%5D%5Brecord_name%5D=%40&create%5B2%5D%5Brecord_ttl%5D=&create%5B2%5D%5Brecord_value%5D='"$FM_SERVER_IP"'&create%5B2%5D%5Brecord_comment%5D=&create%5B2%5D%5Brecord_status%5D=active&submit=Submit' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to add NS's A records to domain!"
  EXIT_CODE="1"
  goto end
fi

# Add sub-domain's A record to domain
curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/zone-records-write.php' \
  --data-raw 'domain_id='"$DOMAIN_ID"'&record_type=A&map=forward&uri=%2Fzone-records.php%3Fmap%3Dforward%26domain_id%3D12%26record_type%3DA&create%5B1%5D%5Brecord_name%5D='"$SUB_DOMAIN_A_RECORD"'&create%5B1%5D%5Brecord_ttl%5D=&create%5B1%5D%5Brecord_value%5D='"$SUB_DOMAIN_A_RECORD_IP"'&create%5B1%5D%5Brecord_comment%5D=&create%5B1%5D%5Brecord_status%5D=active&submit=Submit' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to add sub-domain's A record to domain!"
  EXIT_CODE="1"
  goto end
fi

rm -f curl_output

echo "[*] Restarting fmDNS client..."
docker restart $FMDNS_CLIENT_CONTAINER_NAME

# Wait for fmDNS client
echo "[*] Waiting 10 seconds for fmDNS client..."
sleep 10

# Enable name server
curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/fm-modules/facileManager/ajax/processPost.php' \
  --data-raw 'item_id=1&item_type=servers&item_status=active&action=edit&is_ajax=1' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to enable name server!"
  EXIT_CODE="1"
  goto end
fi

ENABLE_EXTERNAL_NAMESERVERS=`echo "$ENABLE_EXTERNAL_NAMESERVERS" | tr '[:upper:]' '[:lower:]'`
if [ "$ENABLE_EXTERNAL_NAMESERVERS" = "true" ]; then
  # Setting forwarders
  FORWARDERS=""
  if [ "$EXTERNAL_NAMESERVER_1" != "" ]; then
    FORWARDERS="$EXTERNAL_NAMESERVER_1%3B+"
  fi
  if [ "$EXTERNAL_NAMESERVER_2" != "" ]; then
    FORWARDERS="$FORWARDERS$EXTERNAL_NAMESERVER_2%3B+"
  fi
  curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/config-options.php' \
    --data-raw 'action=add&cfg_id=0&cfg_type=global&domain_id=0&server_serial_no=0&cfg_name=forwarders&cfg_data=%7B'"$FORWARDERS"'%7D&cfg_comment=' \
    > curl_output
  STATUS=`echo $?`
  if [ "$STATUS" != "0" ]; then
    cat curl_output | grep 'ERROR:'
    echo "[!] Error: Failed to setting forwarders!"
    EXIT_CODE="1"
    goto end
  fi

  # Enable recursion
  OPTION_ID=`curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/config-options.php' | grep 'recursion' | grep 'tr id' | xargs | tr " " "\n" | grep id | cut -d'=' -f 2`
  curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/config-options.php' \
    --data-raw 'action=edit&cfg_id='"$OPTION_ID"'&cfg_type=global&domain_id=0&server_serial_no=0&cfg_data%5B%5D=yes&cfg_comment=' \
    > curl_output
  STATUS=`echo $?`
  if [ "$STATUS" != "0" ]; then
    cat curl_output | grep 'ERROR:'
    echo "[!] Error: Failed to enable recursion!"
    EXIT_CODE="1"
    goto end
  fi
else
  # Remove forwarders
  OPTION_ID=`curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/config-options.php' | grep 'forwarders' | grep 'tr id' | xargs | tr " " "\n" | grep id | cut -d'=' -f 2`
  curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/fm-modules/facileManager/ajax/processPost.php' \
    --data-raw 'item_id='"$OPTION_ID"'&item_type=options&action=delete&is_ajax=1' \
    > curl_output
  STATUS=`echo $?`
  if [ "$STATUS" != "0" ]; then
    cat curl_output | grep 'ERROR:'
    echo "[!] Error: Failed to remove forwarders!"
    EXIT_CODE="1"
    goto end
  fi

  # Disable recursion
  OPTION_ID=`curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/config-options.php' | grep 'recursion' | grep 'tr id' | xargs | tr " " "\n" | grep id | cut -d'=' -f 2`
  curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/config-options.php' \
    --data-raw 'action=edit&cfg_id='"$OPTION_ID"'&cfg_type=global&domain_id=0&server_serial_no=0&cfg_data%5B%5D=no&cfg_comment=' \
    > curl_output
  STATUS=`echo $?`
  if [ "$STATUS" != "0" ]; then
    cat curl_output | grep 'ERROR:'
    echo "[!] Error: Failed to disable recursion!"
    EXIT_CODE="1"
    goto end
  fi
fi

# Setting allow query
curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/config-options.php' \
  --data-raw 'action=add&cfg_id=0&cfg_type=global&domain_id=0&server_serial_no=0&cfg_name=allow-query&cfg_data=any&cfg_comment=' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to setting allow query!"
  EXIT_CODE="1"
  goto end
fi

# Build configs for name server
curl -s --cookie cookie 'http://'"$FM_SERVER_IP:$FM_SERVER_PORT"'/fm-modules/facileManager/ajax/processPost.php' \
  --data-raw 'item_id%5B%5D='"$FACILE_CLIENT_SERIAL_NUMBER"'&action=bulk&bulk_action=build+config&item_type=servers&rel_url=http%3A%2F%2F'"$FM_SERVER_IP"'%3A'"$FM_SERVER_PORT"'%2Fconfig-servers.php&is_ajax=1' \
  > curl_output
STATUS=`echo $?`
if [ "$STATUS" != "0" ]; then
  cat curl_output | grep 'ERROR:'
  echo "[!] Error: Failed to build configs for name server!"
  EXIT_CODE="1"
  goto end
fi

echo "[*] fmDNS setting finished!"
goto end

end:
rm -f cookie
rm -f curl_output
exit $EXIT_CODE
