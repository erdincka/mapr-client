#!/usr/bin/env bash

# enable ssh early on
service ssh start

set -euo pipefail

# echo "${MAPR_IP} ${MAPR_CLUSTER}" | tee -a /etc/hosts

# curl --insecure --user ${MAPR_USER}:${MAPR_PASS} -T /opt/mapr/conf/ sftp://${MAPR_IP}/opt/mapr/conf/ssl_truststore
echo y | pscp -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/ssl_truststore /opt/mapr/conf/
pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/ssl_truststore.p12 /opt/mapr/conf/
pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/ssl_truststore.pem /opt/mapr/conf/
pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/maprtrustcreds.conf /opt/mapr/conf/
pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/maprtrustcreds.jceks /opt/mapr/conf/
pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/ssl_keystore-signed.pem /opt/mapr/conf/

/opt/mapr/server/configure.sh -N "${MAPR_CLUSTER:-maprdemo.mapr.io}" -c -C "${MAPR_IP}":7222 -HS "${MAPR_IP}"
echo "Client configured"

echo -n "Logging into ${MAPR_CLUSTER}"
while [ ! -f /tmp/maprticket_0 ] ; do
  sleep 5
  echo -n .
  echo "${MAPR_PASS:-mapr}" | maprlogin password -user "${MAPR_USER:-mapr}" -cluster "${MAPR_CLUSTER:-maprdemo.mapr.io}"
done

maprlogin generateticket -user "${MAPR_USER:-mapr}" -type service -out /opt/mapr/conf/maprfuseticket -duration 30:0:0 -renewal 90:0:0
[ -d /mapr ] || mkdir /mapr
service mapr-posix-client-basic start
echo "posix client configured"

echo "Sleep forever..."
while :; do :; done & kill -STOP $! && wait $!
