#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f /etc/sysconfig/scylla-node-exporter ]; then
    . /etc/sysconfig/scylla-node-exporter
elif [ -f /etc/default/scylla-node-exporter ]; then
    . /etc/default/scylla-node-exporter
fi

exec /opt/scylladb/node_exporter/node_exporter $SCYLLA_NODE_EXPORTER_ARGS
