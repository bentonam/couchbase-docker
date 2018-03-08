# start with couchbase
FROM couchbase/server:5.5.0-Mar

# File Author / Maintainer
MAINTAINER Aaron Benton

# Copy the configure script
COPY scripts/configure-node.sh /
COPY scripts/entrypoint.sh /

CMD ["couchbase-server"]
