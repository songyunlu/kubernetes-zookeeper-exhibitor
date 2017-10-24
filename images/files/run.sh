#! /bin/bash -e

# Generates the default exhibitor config and launches exhibitor
ZK_DATA_DIR=${ZK_DATA_DIR:-/var/lib/zookeeper/data}
ZK_LOG_DIR=${ZK_LOG_DIR:-/var/lib/zookeeper/log}
ZK_ENSEMBLE_SIZE=${ZK_ENSEMBLE_SIZE:-0}
ZK_SETTLING_PERIOD=${ZK_SETTLING_PERIOD:-120000}
ZK_FS_CONFIG_DIR=${ZK_FS_CONFIG_DIR:-/var/lib/zookeeper_config}
ZK_BACKUP_CONFIG="--configtype file --fsconfigdir ${ZK_FS_CONFIG_DIR} --filesystembackup true"
ZK_HOSTNAME=$(hostname)
ZK_EXHIBITOR_PORT=${ZK_EXHIBITOR_PORT:-8181}

mkdir -p ${ZK_DATA_DIR} ${ZK_LOG_DIR} ${ZK_FS_CONFIG_DIR}

if [[ -n $ZK_MAX_SERVERS ]] && [[ -n $ZK_STATEFULSET_NAME ]] && [[ -n $ZK_GOVERNING_SERVICE_NAME ]]; then
  for i in $( eval echo {0..$((ZK_MAX_SERVERS-1))}); do
    EXHIBITOR_SERVERS_SPEC="${EXHIBITOR_SERVERS_SPEC}S\:$i\:${ZK_STATEFULSET_NAME}-$i.${ZK_GOVERNING_SERVICE_NAME}"
    if [[ $i -lt $((ZK_MAX_SERVERS-1)) ]]; then
        EXHIBITOR_SERVERS_SPEC="${EXHIBITOR_SERVERS_SPEC},"
    fi
  done
  ZK_HOSTNAME=${ZK_HOSTNAME}.${ZK_GOVERNING_SERVICE_NAME}
else
  EXHIBITOR_SERVERS_SPEC="S\:0\:${ZK_HOSTNAME}"
fi

cat <<- EOF > /opt/exhibitor/defaults.conf
auto-manage-instances-fixed-ensemble-size=$ZK_ENSEMBLE_SIZE
auto-manage-instances-settling-period-ms=$ZK_SETTLING_PERIOD
auto-manage-instances=1
backup-max-store-ms=21600000
backup-period-ms=600000
backup-extra=directory\=${ZK_FS_CONFIG_DIR}
check-ms=30000
cleanup-max-files=20
cleanup-period-ms=300000
client-port=2181
connect-port=2888
election-port=3888
log-index-directory=$ZK_LOG_DIR
observer-threshold=0
servers-spec=${EXHIBITOR_SERVERS_SPEC}
zoo-cfg-extra=tickTime\=2000&initLimit\=10&syncLimit\=5&quorumListenOnAllIPs\=true
zookeeper-data-directory=$ZK_DATA_DIR
zookeeper-install-directory=/opt/zookeeper
zookeeper-log-directory=$ZK_LOG_DIR
EOF
cat /opt/exhibitor/defaults.conf

[[ -n ${ZK_PASSWORD} ]] && {
  ZK_SECURITY="--security web.xml --realm Zookeeper:realm --remoteauth basic:zk"
  echo "zk: ${ZK_PASSWORD},zk" > realm
}

exec 2>&1

java -jar /opt/exhibitor/exhibitor.jar \
  --port ${ZK_EXHIBITOR_PORT} \
  --defaultconfig /opt/exhibitor/defaults.conf \
  --hostname ${ZK_HOSTNAME} \
  ${ZK_BACKUP_CONFIG} \
  ${ZK_SECURITY}
