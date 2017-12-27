# start with couchbase
FROM couchbase:enterprise-5.0.1

# File Author / Maintainer
MAINTAINER Aaron Benton

# Copy the configure script
COPY scripts/configure-node.sh /
COPY scripts/entrypoint.sh /

CMD ["couchbase-server"]
