# Couchbase Docker

A Couchbase container running Couchbase Enterprise Edition v5.0.1 that can be fully configured through environment variables.  See all of the environment variables below for the possible configuration combinations.  

## Tags and Dockerfile

Supported tags and Dockerfile links

- [`latest`](https://github.com/bentonam/couchbase-docker/blob/master/Dockerfile), [`enterprise-5.0.1`](https://github.com/bentonam/couchbase-docker/blob/master/Dockerfile), [`enterprise-5.0.0`](https://github.com/bentonam/couchbase-docker/blob/master/Dockerfile) [`enterprise-5.0.0`](https://github.com/bentonam/couchbase-docker/blob/master/Dockerfile) [`enterprise-4.6.3`](https://github.com/bentonam/couchbase-docker/blob/master/Dockerfile)
- [`community`](https://github.com/bentonam/couchbase-docker/blob/community/Dockerfile), [`community-5.0.1`](https://github.com/bentonam/couchbase-docker/blob/community/Dockerfile),[`community-4.5.1`](https://github.com/bentonam/couchbase-docker/blob/community/Dockerfile)

## Examples

The following will start a container with all of the default values.  You will have a Couchbase Server container with the default bucket, all services running, the username is `Administrator` and the password is `password`.  Additionally, there is an RBAC user created whose username is `default` and the password is `password`.

```bash
docker run -d --name my-couchbase -p 8091-8094:8091-8094 -p 11210:11210 bentonam/couchbase-docker
```

If you want the default settings but also want the `beer-sample` and `travel-sample` buckets.  Note it does take a little longer to load the sample buckets.

```bash
docker run -d --name my-couchbase -p 8091-8094:8091-8094 -p 11210:11210 -e SAMPLE_BUCKETS=beer-sample,travel-sample bentonam/couchbase-docker
```

If you want to have a container running just the `data` service, with 500mb of memory in a bucket called `ecommerce`

```bash
docker run -d --name my-couchbase -p 8091-8094:8091-8094 -p 11210:11210 -e CLUSTER_RAMSIZE=500 -e BUCKET_RAMSIZE=500 -e BUCKET=ecommerce -e SERVICES=data bentonam/couchbase-docker
```

If you want to have a 3 node cluster, notice the first container configures the cluster and creates the buckets, the second is just joined to the cluster and the third is joined and rebalances the cluster.

```bash
docker run -d --name couchbase-node1 -p 8091-8094:8091-8094 -p 11210:11210 -e CLUSTER_RAMSIZE=500 -e BUCKET_RAMSIZE=500 -e BUCKET=ecommerce -e SERVICES=data bentonam/couchbase-docker
docker run -d --name couchbase-node2 --link couchbase-node1 -e SERVICES=data -e NODE_TYPE=child -e CLUSTER=couchbase-node1 bentonam/couchbase-docker
docker run -d --name couchbase-node3 --link couchbase-node1 --link couchbase-node2 -e SERVICES=data -e NODE_TYPE=child -e CLUSTER=couchbase-node1 -e REBALANCE=1 bentonam/couchbase-docker
```

**docker-compose.yaml**

```yaml
version: '3'
services:
  couchbase-demo:
    image: bentonam/couchbase-docker:enterprise
    container_name: couchbase-demo
    ports:
      - "8091-8094:8091-8094"
      - "11210:11210"
    environment:
      CLUSTER_USERNAME: Administrator
      CLUSTER_PASSWORD: somepassword
      CLUSTER_NAME: My Couchbase Cluster
      SERVICES: data,index,query,fts
      CLUSTER_RAMSIZE: 500
      BUCKET: ecommerce
      BUCKET_RAMSIZE: 300
      SAMPLE_BUCKETS: beer-sample,travel-sample
      NODE_INIT_INDEX_PATH: /opt/couchbase/var/lib/couchbase/indexes
      RBAC_USERNAME: someuser
      RBAC_PASSWORD: password123
      RBAC_PASSWORD: bucket_full_access[ecommerce]
```

## Environment Variables

The following environment variables are supported.  None of these environment variables are required, be sure to check the defaults:

- `AUTO_FAILOVER_TIMEOUT`: A timeout in seconds that expires to trigger the auto failover.  The default value is **120**.
- `BUCKET`: The name of the bucket to create and use.  The default value is **default**.
- `BUCKET_EVICTION_POLICY`: The evication policy to use.  The default value is **valueOnly**.  Valid values are:
	- valueOnly - Only eject the document values from memory, keeping the key
	- fullEviction - Eject both the key and the value from memory
- `BUCKET_PRIORITY`: The bucket priority compared to other buckets.  The default value is **high**.  Valid values are:
	- high
	- low
- `BUCKET_RAMSIZE`: Bucket RAM quota in MB. The default value is **100**.
- `BUCKET_REPLICA`: The number of replicas that should be kept for each document on different nodes.  The default value is **1**.  Valid values are
	- 0
	- 1
	- 2
	- 3
- `BUCKET_TYPE`: The type of bucket to create.  The default value is **couchbase**.  Valid values are:
	- couchbase - This should almost always be used
	- memcached - This really should never be used unless absolutely needed and justified
- `CLUSTER`: The IP Address or Hostname of another node / container that is already in the cluster.  This is only used if `NODE_TYPE` is not `DEFAULT`. The default is an empty string.
- `CLUSTER_FTS_RAMSIZE`: The per-node FTS service RAM quota in MB. The default value is **256**.
- `CLUSTER_INDEX_RAMSIZE`: The per-node index services RAM quota in MB.  The default value is **256**.
- `CLUSTER_NAME`: The name of the cluster, if none is specified an empty string is used.
- `CLUSTER_PASSWORD`: The Administrator password to use when initializing the cluster or an existing password if creating a new container to join to the cluster. The default value is **password**.
- `CLUSTER_USERNAME`: The Administrator username to use when initializing the cluster or an existing username if creating a new container to join to the cluster. The default value is **Administrator**.
- `CLUSTER_RAMSIZE`: The per-node data services RAM quota in MB. The default value is **400**
- `COMPACTION_DB_PERCENTAGE`: Starts data compaction once data file fragmentation has reached this percentage.  The default value is **30**.
- `COMPACTION_GSI_INTERVAL`: A comma separated list of days compaction can run (Circular mode only).  Valid values are:
	- Monday
	- Tuesday
	- Wednesday
	- Thursday
	- Friday
	- Saturday
	- Sunday
- `GSI_COMPACTION_MODE`: Allow view and data file compaction at the same time.  The default value is **circular**.  valid values are:
	- append = Appends mutations to the end of the index
	- circular = As mutations arrive instead of appending new pages to the end of the file, write operations look for resuing the orphaned space in the file
- `COMPACTION_GSI_PERCENTAGE`: Starts compaction once gsi file fragmentation has reached this percentage (Append mode only).  The default value is **30**.
- `COMPACTION_GSI_PERIOD_FROM` Allow gsi compaction to run after this time (Circular mode only). The time is specified in HH:MM.
- `COMPACTION_GSI_PERIOD_TO` Allow gsi compaction to run before this time (Circular mode only). The time is specified in HH:MM.
- `COMPACTION_VIEW_PERCENTAGE`: Starts view compaction once view file fragmentation has reached this percentage.  The default value is **30**.
- `COMPACTION_PERIOD_FROM`: Allow compaction to run after this time. The time is specified in HH:MM.
- `COMPACTION_PERIOD_TO`: Allow compaction to run before this time. The time is specified in HH:MM.
- `EMAIL_ENCRYPT`: Whether or not the emails should be encrypted.  The default value is **0**.  Valid values are:
	- 1 = yes
	- 0 = no
- `EMAIL_HOST`: Email server hostname.
- `EMAIL_PASSWORD`: Email server password.
- `EMAIL_PORT`: Email server port.
- `EMAIL_RECIPIENTS`: Email recipients, separate addresses with , or ;
- `EMAIL_SENDER`: Sender email address.
- `EMAIL_USER`: Email server username.
- `ENABLE_AUTO_FAILOVER`: Whether or not auto failover should be enabled or not.  The default value is **1**.
- `ENABLE_COMPACTION_ABORT`: Abort compaction if running outside of the accepted interval.  The default value is **1**.  Valid values are:
	- 1 = yes
	- 0 = no
- `ENABLE_COMPACTION_PARALLEL`: Allow view and data file compaction at the same time.  The default value is **0**.  valid values are:
	- 1 = yes
	- 0 = no
- `ENABLE_EMAIL_ALERT`: Whether or not email alerts should be enabled.  The default value is **0**.  Valid values are:
	- 1 = yes
	- 0 = no
- `ENABLE_FLUSH`: Enables and disables bucket flushing.  The default value is **0**.  Valid values are:
	- 1 = yes
	- 0 = no
- `ENABLE_GSI_COMPACTION_ABORT`: Abort gsi compaction if when run outside of the accepted interaval (Circular mode only).  The default value is **1**.  Valid values are:
	- 1 = yes
	- 0 = no
- `ENABLE_INDEX_REPLICA`: Enables a defined number of replicas.  The default value is **0**.  Valid values are:
	- 1 = yes
	- 0 = no
- `INDEX_STORAGE_SETTING`: Index storage type can be.  The default value is **default**.  Valid values are:
	- default - The default index storage is on disk
	- memopt - Memory optimized GSI indexes are only available in Couchbase Enterprise
- `NODE_INIT_DATA_PATH`: **/opt/couchbase/var/lib/couchbase/data**
- `NODE_INIT_INDEX_PATH`: **/opt/couchbase/var/lib/couchbase/indexes**
- `NODE_INIT_HOSTNAME`: **127.0.0.1**
- `NODE_TYPE`: The type of node to bring up.  The default value is **DEFAULT**.  Valid values are:
	- DEFAULT
	- CHILD
- `RBAC_USERNAME`: Specifies the username of the RBAC user to create. The default value is the name of the `BUCKET`
- `RBAC_PASSWORD`: Specifies the password to be used for an RBAC user profile. The default value is the `CLUSTER_PASSWORD`
- `RBAC_ROLES`: Specifies the roles to be given to an RBAC user profile.  The default value is `admin`
- `SAMPLE_BUCKETS`: A comma-delimited list of sample buckets to load.  The default value is an empty string.  Valid values are:
	- beer-sample
	- gamesim-sample
	- travel-sample
- `SERVICES`: The services to run on the node, the default value is **data,index,query,fts**.  Valid values are:
	- data - The data service
	- index - The GSI service for building N1QL indexes
	- query - The N1QL query service
	- fts - The Full Text Search service
- `REBALANCE`: Whether or not the a cluster rebalance should be issued after a new node has been joined to the cluster. The default value is **0**.  The valid values are:
	- 1 = yes
	- 0 = no
