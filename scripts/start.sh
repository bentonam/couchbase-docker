docker run -dt \
  -e NODE_TYPE=MASTER \
  -e CLUSTER_USERNAME=Administrator \
  -e CLUSTER_PASSWORD=password \
  -e CLUSTER_NAME="Caching POC" \
  -e SERVICES=data \
  -e AUTO_FAILOVER_TIMEOUT=60 \
  -e ENABLE_AUTO_FAILOVER=1 \
  -e CLUSTER_RAMSIZE=300 \
  -p 8091:8091 \
    artifactory.marketamerica.com:8443/cache-microservice/couchbase

sleep 5

docker run -dt \
  -e NODE_TYPE=SLAVE \
  -e CLUSTER=172.17.0.2:8091 \
  -e CLUSTER_USERNAME=Administrator \
  -e CLUSTER_PASSWORD=password \
  -e SERVICES=data \
  artifactory.marketamerica.com:8443/cache-microservice/couchbase

sleep 2

docker run -dt \
  -e NODE_TYPE=SLAVE \
  -e CLUSTER=172.17.0.2:8091 \
  -e CLUSTER_USERNAME=Administrator \
  -e CLUSTER_PASSWORD=password \
  -e SERVICES=data \
  -e REBALANCE=TRUE \
  artifactory.marketamerica.com:8443/cache-microservice/couchbase
