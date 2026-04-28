#!/bin/bash
#
# install.sh - Install scylla-node-exporter for relocatable/unified builds.
# Usage: ./install.sh [--root ROOT] [--prefix PREFIX] [--sysconfdir SYSCONFDIR]
#                     [--packaging]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root=""
prefix="/opt/scylladb"
sysconfdir="/etc/sysconfig"
packaging=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            root="$2"
            shift 2
            ;;
        --prefix)
            prefix="$2"
            shift 2
            ;;
        --sysconfdir)
            sysconfdir="$2"
            shift 2
            ;;
        --packaging)
            packaging=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

install -d -m 0755 "${root}${prefix}/node_exporter"
install -d -m 0755 "${root}${prefix}/node_exporter/licenses"
install -d -m 0755 "${root}${sysconfdir}"
install -d -m 0755 "${root}${prefix}/supervisor"
install -d -m 0755 "${root}/etc/systemd/system/scylla-node-exporter.service.d"

install -m 0755 "${SCRIPT_DIR}/build/node_exporter.stripped" \
    "${root}${prefix}/node_exporter/node_exporter"

for f in LICENSE NOTICE; do
    if [ -f "${SCRIPT_DIR}/build/$f" ]; then
        install -m 0644 "${SCRIPT_DIR}/build/$f" \
            "${root}${prefix}/node_exporter/licenses/$f"
    fi
done

install -m 0644 "${SCRIPT_DIR}/dist/sysconfig/scylla-node-exporter" \
    "${root}${sysconfdir}/scylla-node-exporter"

if ! $packaging; then
    install -d -m 0755 "${root}/usr/lib/systemd/system"
    install -m 0644 "${SCRIPT_DIR}/dist/systemd/scylla-node-exporter.service" \
        "${root}/usr/lib/systemd/system/scylla-node-exporter.service"
fi

install -m 0644 "${SCRIPT_DIR}/dist/systemd/scylla-node-exporter.service.d/dependencies.conf" \
    "${root}/etc/systemd/system/scylla-node-exporter.service.d/dependencies.conf"

install -m 0755 "${SCRIPT_DIR}/dist/supervisor/scylla-node-exporter.sh" \
    "${root}${prefix}/supervisor/scylla-node-exporter.sh"

echo "scylla-node-exporter installed to ${root}${prefix}/node_exporter"
