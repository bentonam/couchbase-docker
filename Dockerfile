# start with couchbase
FROM couchbase:community-4.5.1

# File Author / Maintainer
MAINTAINER Aaron Benton

# Copy the configure script
COPY scripts/configure-node.sh /
COPY scripts/entrypoint.sh /

CMD ["couchbase-server"]
