set -m

### DEFAULTS
NODE_TYPE=${NODE_TYPE:='DEFAULT'}
CLUSTER_USERNAME=${CLUSTER_USERNAME:='Administrator'}
CLUSTER_PASSWORD=${CLUSTER_PASSWORD:='password'}
CLUSTER_RAMSIZE=${CLUSTER_RAMSIZE:=300}
SERVICES=${SERVICES:='data,index,query,fts,eventing'}
BUCKET=${BUCKET:='default'}
BUCKET_RAMSIZE=${BUCKET_RAMSIZE:=100}
BUCKET_TYPE=${BUCKET_TYPE:=couchbase}
RBAC_USERNAME=${RBAC_USERNAME:=$BUCKET}
RBAC_PASSWORD=${RBAC_PASSWORD:=$CLUSTER_PASSWORD}
RBAC_ROLES=${RBAC_ROLES:='admin'}

sleep 2
echo ' '
printf 'Waiting for Couchbase Server to start'
until $(curl --output /dev/null --silent --head --fail -u $CLUSTER_USERNAME:$CLUSTER_PASSWORD http://localhost:8091/pools); do
  printf .
  sleep 1
done

echo ' '
echo Couchbase Server has started
echo Starting configuration for $NODE_TYPE node

echo Configuring Individual Node Settings
/opt/couchbase/bin/couchbase-cli node-init \
  --cluster localhost:8091 \
  --user=$CLUSTER_USERNAME \
  --password=$CLUSTER_PASSWORD \
  --node-init-data-path=${NODE_INIT_DATA_PATH:='/opt/couchbase/var/lib/couchbase/data'} \
  --node-init-index-path=${NODE_INIT_INDEX_PATH:='/opt/couchbase/var/lib/couchbase/indexes'} \
  --node-init-hostname=${NODE_INIT_HOSTNAME:='127.0.0.1'} \
> /dev/null

if [[ "${NODE_TYPE}" == "DEFAULT" ]]; then
  # configure master node
  echo Configuring Cluster
  CMD="/opt/couchbase/bin/couchbase-cli cluster-init"
  CMD="$CMD --cluster localhost:8091"
  CMD="$CMD --cluster-username $CLUSTER_USERNAME"
  CMD="$CMD --cluster-password $CLUSTER_PASSWORD"
  CMD="$CMD --cluster-ramsize $CLUSTER_RAMSIZE"
  # is the index service going to be running?
  if [[ $SERVICES == *"index"* ]]; then
    CMD="$CMD --index-storage-setting ${INDEX_STORAGE_SETTING:=default}"
    CMD="$CMD --cluster-index-ramsize ${CLUSTER_INDEX_RAMSIZE:=256}"
  fi
  # is the fts service going to be running?
  if [[ $SERVICES == *"fts"* ]]; then
    CMD="$CMD --cluster-fts-ramsize ${CLUSTER_FTS_RAMSIZE:=256}"
  fi
  # is the eventing service going to be running?
  if [[ $SERVICES == *"eventing"* ]]; then
    CMD="$CMD --cluster-eventing-ramsize ${CLUSTER_EVENTING_RAMSIZE:=256}"
  fi
  # is the analytics service going to be running?
  if [[ $SERVICES == *"analytics"* ]]; then
    CMD="$CMD --cluster-analytics-ramsize ${CLUSTER_ANALYTICS_RAMSIZE:=1024}"
  fi
  CMD="$CMD --services=$SERVICES"
  CMD="$CMD > /dev/null"
  eval $CMD

  echo Setting the Cluster Name
  /opt/couchbase/bin/couchbase-cli setting-cluster \
    --cluster localhost:8091 \
    --user $CLUSTER_USERNAME \
    --password $CLUSTER_PASSWORD \
    --cluster-name "$(echo $CLUSTER_NAME)" \
  > /dev/null

  echo Configuring Auto Failover Settings
  /opt/couchbase/bin/couchbase-cli setting-autofailover \
    --cluster localhost:8091 \
    --user $CLUSTER_USERNAME \
    --password $CLUSTER_PASSWORD \
    --auto-failover-timeout ${AUTO_FAILOVER_TIMEOUT:=120} \
    --enable-auto-failover ${ENABLE_AUTO_FAILOVER:=1} \
  > /dev/null

  # create the bucket
  echo Creating $BUCKET bucket
  /opt/couchbase/bin/couchbase-cli bucket-create \
    --cluster localhost:8091 \
    --username $CLUSTER_USERNAME \
    --password $CLUSTER_PASSWORD \
    --bucket $BUCKET \
    --bucket-ramsize $BUCKET_RAMSIZE \
    --bucket-type $BUCKET_TYPE \
    --bucket-priority ${BUCKET_PRIORITY:=low} \
    --enable-index-replica ${ENABLE_INDEX_REPLICA:=0} \
    --enable-flush ${ENABLE_FLUSH:=0} \
    --bucket-replica ${BUCKET_REPLICA:=1} \
    --bucket-eviction-policy ${BUCKET_EVICTION_POLICY:=valueOnly} \
    --compression-mode ${BUCKET_COMPRESSION:=off} \
    --max-ttl ${BUCKET_MAX_TTL:=0} \
    --wait \
  > /dev/null

  # rbac user
  echo Creating RBAC user $RBAC_USERNAME
  /opt/couchbase/bin/couchbase-cli user-manage \
    --cluster localhost:8091 \
    --username $CLUSTER_USERNAME \
    --password $CLUSTER_PASSWORD \
    --set \
    --rbac-username $RBAC_USERNAME \
    --rbac-password $RBAC_PASSWORD \
    --roles $RBAC_ROLES \
    --auth-domain local \
  > /dev/null

  # setting alerts
  echo Configuring Alert Settings
  if [ -z ${ENABLE_EMAIL_ALERT+x} ]; then
    ENABLE_EMAIL_ALERT=0;
  fi
  CMD="/opt/couchbase/bin/couchbase-cli setting-alert"
  CMD="$CMD --cluster localhost:8091"
  CMD="$CMD --user=$CLUSTER_USERNAME"
  CMD="$CMD --password=$CLUSTER_PASSWORD"
  CMD="$CMD --enable-email-alert=$ENABLE_EMAIL_ALERT"
  if [[ "${ENABLE_EMAIL_ALERT}" == "1" ]]; then
    CMD="$CMD --email-recipients=$EMAIL_RECIPIENTS"
    CMD="$CMD --email-sender=$EMAIL_SENDER"
    CMD="$CMD --email-user=$EMAIL_USER"
    CMD="$CMD --email-password=$EMAIL_PASSWORD"
    CMD="$CMD --email-host=$EMAIL_HOST"
    CMD="$CMD --email-port=$EMAIL_PORT"
    CMD="$CMD --enable-email-encrypt=${EMAIL_ENCRYPT:=0}"
    CMD="$CMD --alert-auto-failover-node"
    CMD="$CMD --alert-auto-failover-max-reached"
    CMD="$CMD --alert-auto-failover-node-down"
    CMD="$CMD --alert-auto-failover-cluster-small"
    CMD="$CMD --alert-auto-failover-disabled"
    CMD="$CMD --alert-ip-changed"
    CMD="$CMD --alert-disk-space"
    CMD="$CMD --alert-meta-overhead"
    CMD="$CMD --alert-meta-oom"
    CMD="$CMD --alert-write-failed"
    CMD="$CMD --alert-audit-msg-dropped"
  fi
  CMD="$CMD > /dev/null"
  eval $CMD

  # compaction settings
  echo Configuring Compaction Settings
  CMD="/opt/couchbase/bin/couchbase-cli setting-compaction"
  CMD="$CMD --cluster localhost:8091"
  CMD="$CMD --user=$CLUSTER_USERNAME"
  CMD="$CMD --password=$CLUSTER_PASSWORD"
  CMD="$CMD --compaction-db-percentage=${COMPACTION_DB_PERCENTAGE:=30}"
  CMD="$CMD --compaction-view-percentage=${COMPACTION_VIEW_PERCENTAGE:=30}"
  if [ -z ${COMPACTION_PERIOD_FROM+x} ]; then
    if [ -z ${COMPACTION_PERIOD_TO+x} ]; then
      CMD="$CMD --compaction-period-from=$COMPACTION_PERIOD_FROM"
      CMD="$CMD --compaction-period-to=$COMPACTION_PERIOD_TO"
      CMD="$CMD --enable-compaction-parallel=${ENABLE_COMPACTION_PARALLEL:=0}"
    fi
  fi

  ## add gsi compaction settings
  if [[ $(/opt/couchbase/bin/couchbase-server --version | grep -o "EE") == "EE" ]]; then
    CMD="$CMD --gsi-compaction-mode=${GSI_COMPACTION_MODE:=circular}"
    if [[ "${GSI_COMPACTION_MODE}" == "append" ]]; then
      CMD="$CMD --compaction-gsi-percentage=${COMPACTION_GSI_PERCENTAGE:=30}"
    fi
    if [[ "${GSI_COMPACTION_MODE}" == "circular" ]]; then
      CMD="$CMD --compaction-gsi-interval=${COMPACTION_GSI_INTERVAL:=Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday}"
      if [ -z ${COMPACTION_PERIOD_FROM+x} ]; then
        if [ -z ${COMPACTION_PERIOD_TO+x} ]; then
          CMD="$CMD --compaction-gsi-period-from=$COMPACTION_GSI_PERIOD_FROM"
          CMD="$CMD --compaction-gsi-period-to=$COMPACTION_GSI_PERIOD_TO"
        fi
      fi
    fi
  fi
  CMD="$CMD > /dev/null"
  eval $CMD

  # sample buckets
  if [ -n "$SAMPLE_BUCKETS" ]; then
    # loop over the comma-delimited list of sample buckets i.e. beer-sample,travel-sample
    for SAMPLE in $(echo $SAMPLE_BUCKETS | sed "s/,/ /g")
    do
      # make sure the sample requested actually exists
      if [ -e /opt/couchbase/samples/$SAMPLE.zip ]; then
        # load the sample documents into the bucket
        echo Loading $SAMPLE bucket
        /opt/couchbase/bin/cbdocloader \
          -n localhost:8091 \
          -u $CLUSTER_USERNAME \
          -p $CLUSTER_PASSWORD \
          -b $SAMPLE \
          -s 100 \
          /opt/couchbase/samples/$SAMPLE.zip \
        > /dev/null 2>&1
      else
        echo Skipping... the $SAMPLE is not available
      fi
    done
  fi
else
  # check to see if the CLUSTER strings contains :8091 if it doesn't then add it
  if [[ ${CLUSTER} != *":8091" ]];then
    CLUSTER="$CLUSTER:8091"
  fi
  echo Waiting for $CLUSTER to become available
  until $(curl --output /dev/null --silent --head --fail -u $CLUSTER_USERNAME:$CLUSTER_PASSWORD http://${CLUSTER}/pools); do
    printf .
    sleep 1
  done
  echo ' '
  echo Adding new Node to the cluster at $CLUSTER
  /opt/couchbase/bin/couchbase-cli server-add \
    --cluster $CLUSTER \
    --user=$CLUSTER_USERNAME \
    --password=$CLUSTER_PASSWORD \
    --server-add="$(ifconfig eth0 | grep inet | grep -o 'inet addr:[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | cut -c 11-):8091" \
    --server-add-username=$CLUSTER_USERNAME \
    --server-add-password=$CLUSTER_PASSWORD \
    --services=$SERVICES \
  > /dev/null 2>&1

  if [[ "${REBALANCE}" == "1" ]]; then
    echo Rebalancing Cluster
    if (/opt/couchbase/bin/couchbase-cli rebalance-status --cluster $CLUSTER --user $CLUSTER_USERNAME --password  $CLUSTER_PASSWORD | grep -q running) then
      echo Only one rebalance operation can be done at a time, waiting for the current rebalance to complete
      until $(couchbase-cli rebalance-status --cluster $CLUSTER --user $CLUSTER_USERNAME --password $CLUSTER_PASSWORD | grep -q notRunning); do
        echo .
        sleep 5
      done
    fi
    /opt/couchbase/bin/couchbase-cli rebalance \
      --cluster $CLUSTER \
      --user=$CLUSTER_USERNAME \
      --password=$CLUSTER_PASSWORD \
    > /dev/null
  fi

fi

echo The new $NODE_TYPE node has been successfully configured
