# scylladb-node-exporter

Standalone packaging of [Prometheus node_exporter](https://github.com/prometheus/node_exporter) for ScyllaDB.

This repository builds the upstream node_exporter from source with the pinned Go toolchain, strips it, and produces RPM/DEB packages that are published to the shared ScyllaDB package repository.

Building from source with the latest Go clears Go stdlib/toolchain CVEs, and
`build.sh` additionally bumps the `golang.org/x/*` dependency modules to their
latest patched releases to clear dependency CVEs (set `PATCH_DEPS=0` to build
pristine upstream sources). CI scans the resulting binary with
[Trivy](https://github.com/aquasecurity/trivy) and fails on fixable
HIGH/CRITICAL vulnerabilities.

## Versioning

The version follows the upstream node_exporter version with a ScyllaDB packaging revision suffix:
- Format: `<upstream_version>-<revision>` (e.g. `1.11.1-1`)
- The upstream version is in the `VERSION` file
- The Go toolchain used to build is pinned in `.go-version`

The packaging revision is bumped (e.g. `1.11.1-1` → `1.11.1-2`) when the
upstream node_exporter source is unchanged but the binary is rebuilt with a
newer Go toolchain — so a Go-only rebuild is distinguishable. The
`check-upstream` workflow proposes both kinds of update automatically:
a new node_exporter release resets the revision to `-1`, while a newer Go
release bumps the revision.

## Building

Requires a Go toolchain (matching `.go-version`) and `git` on PATH.

```bash
# Clone the upstream tag and build node_exporter from source
make build

# Build and run upstream's unit, end-to-end and metrics/rules checks
make test

# Build and strip (default target; also produces debuginfo)
make all

# Clean
make clean
```

## Container images

Every tagged release publishes a multi-arch (amd64/arm64) OCI image to
`scylladb/scylladb-node-exporter` on Docker Hub, tagged with the release
version and `latest`. The image is assembled from the same stripped,
Trivy-scanned binaries produced for the RPM/DEB/relocatable packages (see
`Dockerfile`), on top of `registry.access.redhat.com/ubi9/ubi-minimal`.

Each published image is submitted to Red Hat for container certification via
`preflight check container --submit=true`; maintainers are notified with a
GitHub issue if certification fails.

## Repository Structure

```
├── VERSION              # Package version (upstream-revision)
├── .go-version          # Pinned Go toolchain used to build
├── build.sh             # Clone upstream tag and build from source
├── Makefile             # Build: build-from-source, strip, debuginfo
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
