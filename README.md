# scylladb-node-exporter

Standalone packaging of [Prometheus node_exporter](https://github.com/prometheus/node_exporter) for ScyllaDB.

This repository downloads the upstream node_exporter binary, strips it, and produces RPM/DEB packages that are published to the shared ScyllaDB package repository.

## Versioning

The version follows the upstream node_exporter version with a ScyllaDB packaging revision suffix:
- Format: `<upstream_version>-<revision>` (e.g. `1.10.2-1`)
- The upstream version is in the `VERSION` file

## Building

```bash
# Download upstream binary
make download

# Extract and strip
make all

# Clean
make clean
```

## Repository Structure

```
├── VERSION              # Package version (upstream-revision)
├── download.sh          # Download upstream binary with checksum verification
├── Makefile             # Build: extract, strip, debuginfo
├── dist/
│   ├── redhat/          # RPM spec
│   ├── debian/          # Debian packaging
│   ├── systemd/         # systemd unit files
│   ├── sysconfig/       # sysconfig defaults
│   └── supervisor/      # Docker supervisor scripts
├── install.sh           # Relocatable install script
└── scripts/
    └── create-relocatable-package.py
```
