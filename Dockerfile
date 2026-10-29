# Multi-arch image assembled from the stripped node_exporter binaries that CI
# already builds and scans (see .github/workflows/release.yaml). Binaries are
# copied in per-arch rather than compiled here, so `docker buildx build
# --platform linux/amd64,linux/arm64` needs no QEMU emulation.
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ARG TARGETARCH
ARG VERSION=latest
ARG RELEASE=1

LABEL name="scylladb-node-exporter" \
      vendor="ScyllaDB" \
      maintainer="ScyllaDB <support@scylladb.com>" \
      summary="Prometheus exporter for hardware and OS metrics" \
      description="Prometheus exporter for hardware and OS metrics exposed by *NIX kernels, built by ScyllaDB from the upstream node_exporter project." \
      version="${VERSION}" \
      release="${RELEASE}"

COPY dist/${TARGETARCH}/node_exporter /bin/node_exporter
COPY dist/${TARGETARCH}/LICENSE /licenses/LICENSE
COPY dist/${TARGETARCH}/NOTICE /licenses/NOTICE

USER 65534:65534
EXPOSE 9100

ENTRYPOINT ["/bin/node_exporter"]
