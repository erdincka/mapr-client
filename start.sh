#!/usr/bin/env bash

set -euo pipefail

## Ensure user
useradd -u 5000 -U -m -d /home/${MAPR_USER} -s /bin/bash -G sudo ${MAPR_USER}
echo "${MAPR_USER}:${MAPR_PASS}" | chpasswd
echo "root:${MAPR_PASS}" | chpasswd
echo "mapr ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/mapr

echo n | pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/ssl_truststore /opt/mapr/conf/
echo n | pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/ssl_truststore.p12 /opt/mapr/conf/
echo n | pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/ssl_truststore.pem /opt/mapr/conf/
echo n | pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/maprtrustcreds.conf /opt/mapr/conf/
echo n | pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/maprtrustcreds.jceks /opt/mapr/conf/
echo n | pscp -P 22 -pw "${MAPR_PASS}" -r ${MAPR_USER}@${MAPR_IP}:/opt/mapr/conf/ssl_keystore-signed.pem /opt/mapr/conf/

/opt/mapr/server/configure.sh -N "${MAPR_CLUSTER}" -c -C "${MAPR_IP}":7222 -HS "${MAPR_IP}"
echo "Client configured"

echo -n "Connecting to ${MAPR_CLUSTER}"
while [ ! -f /tmp/maprticket_0 ] ; do
  sleep 5
  echo -n .
  echo "${MAPR_PASS}" | maprlogin password -user "${MAPR_USER}" -cluster "${MAPR_CLUSTER}"
done

# enable ssh
service ssh start

# echo "Sleep forever..."
# while :; do :; done & kill -STOP $! && wait $!

exec "$@"
