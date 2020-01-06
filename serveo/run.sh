#!/bin/bash
set -e

CONFIG_PATH=/data/options.json

SERVER="$(jq --raw-output '.server' $CONFIG_PATH)"
PRIVATE_KEY="$(jq --raw-output '.private_key' ${CONFIG_PATH})"
DOMAIN_1="$(jq --raw-output '.domain_1' $CONFIG_PATH)"
ALIAS_1="$(jq --raw-output '.alias_1' $CONFIG_PATH)"
IP_OR_HOSTNAME_1="$(jq --raw-output '.ip_or_hostname_1' $CONFIG_PATH)"
PORT1FROM="$(jq --raw-output '.port1from' $CONFIG_PATH)"
PORT1TO="$(jq --raw-output '.port1to' $CONFIG_PATH)"
DOMAIN_2="$(jq --raw-output '.domain_3' $CONFIG_PATH)"
ALIAS_2="$(jq --raw-output '.alias_2' $CONFIG_PATH)"
IP_OR_HOSTNAME_2="$(jq --raw-output '.ip_or_hostname_2' $CONFIG_PATH)"
PORT2FROM="$(jq --raw-output '.port2from' $CONFIG_PATH)"
PORT2TO="$(jq --raw-output '.port2to' $CONFIG_PATH)"
DOMAIN_3="$(jq --raw-output '.domain_3' $CONFIG_PATH)"
ALIAS_3="$(jq --raw-output '.alias_3' $CONFIG_PATH)"
IP_OR_HOSTNAME_3="$(jq --raw-output '.ip_or_hostname_3' $CONFIG_PATH)"
PORT3FROM="$(jq --raw-output '.port3from' $CONFIG_PATH)"
PORT3TO="$(jq --raw-output '.port3to' $CONFIG_PATH)"
RETRY_TIME="$(jq --raw-output '.retry_time' $CONFIG_PATH)"

if [ "${IP_OR_HOSTNAME_1}" == "" ]
then
    IP_OR_HOSTNAME_1="localhost"
fi

if [ "${DOMAIN_1}" == "" ]
then
    DOMAIN_1="${ALIAS_1}.${SERVER}"
fi

TUNNEL_1="-R ${DOMAIN_1}:${PORT1TO}:${IP_OR_HOSTNAME_1}:${PORT1FROM}"
TUNNEL_2=""
TUNNEL_3=""

echo "Logs for debug '${TUNNEL_1}' "


if [ "${PORT2FROM}" -ne "0" ] && ["${PORT2TO}" -ne "0"]
then
    if [ "${IP_OR_HOSTNAME_2}" == "" ]
    then
        IP_OR_HOSTNAME_2="localhost"
    fi
    if [ "${DOMAIN_2}" == "" ]
    then
        DOMAIN_2="${ALIAS_2}.${SERVER}"
    fi
    TUNNEL_2=" -R ${DOMAIN_2}:${PORT2TO}:${IP_OR_HOSTNAME_2}:${PORT2FROM}"
fi

echo "Logs for debug '${TUNNEL_2}' "


if [ "${PORT3FROM}" -ne "0" ] && ["${PORT3TO}" -ne "0"]
then
    if [ "${IP_OR_HOSTNAME_3}" == "" ]
    then
        IP_OR_HOSTNAME_3="localhost"
    fi
    if [ "${DOMAIN_3}" == "" ]
    then
        DOMAIN_3="${ALIAS_3}.${SERVER}"
    fi
    TUNNEL_3=" -R  ${DOMAIN_3}:${PORT3TO}:${IP_OR_HOSTNAME_3}:${PORT3FROM}"
fi

echo "Logs for debug '${TUNNEL_3}' "

IDENTITY=""
if [[ "${PRIVATE_KEY}" != "" ]]
then
    echo "${PRIVATE_KEY}" >> /private_key
    chmod 600 /private_key
    IDENTITY="-i /private_key"
fi

CMD="/bin/bash -c 'sleep ${RETRY_TIME} && ssh ${IDENTITY} -tt -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -o ServerAliveCountMax=3 ${TUNNEL_1}${TUNNEL_2}${TUNNEL_3} ${SERVER}'"

echo "Running '${CMD}' through supervisor!"

cat > /etc/supervisor-docker.conf << EOL
[supervisord]
user=root
nodaemon=true
logfile=/dev/null
logfile_maxbytes=0
EOL
cat >> /etc/supervisor-docker.conf << EOL
[program:serveo]
command=${CMD}
autostart=true
autorestart=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
redirect_stderr=true
EOL

exec supervisord -c /etc/supervisor-docker.conf
