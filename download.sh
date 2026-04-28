#!/bin/bash
#
# Download the upstream Prometheus node_exporter binary.
# Usage: ./download.sh [--output-dir DIR]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(sed 's/-.*//' "$SCRIPT_DIR/VERSION")

declare -A CHECKSUMS=(
    ["x86_64"]=9f5ea48e5bc7b656f8a91a32e7d7deb89f70f73dabd0d974418aca15f37d6810
    ["aarch64"]=ba1886efbd76cb96b0087c695ea8d1b9cb6e8aa946c996d744e9ee16c8e3591a
)

declare -A GO_ARCH=(
    ["x86_64"]=amd64
    ["aarch64"]=arm64
)

ARCH=$(arch)
OUTPUT_DIR="${SCRIPT_DIR}/build"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

FILENAME="node_exporter-${VERSION}.linux-${GO_ARCH[$ARCH]}.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${FILENAME}"
EXPECTED_CHECKSUM="${CHECKSUMS[$ARCH]}"

mkdir -p "$OUTPUT_DIR"
FILEPATH="${OUTPUT_DIR}/${FILENAME}"

if [ -f "$FILEPATH" ]; then
    ACTUAL=$(sha256sum "$FILEPATH" | awk '{print $1}')
    if [ "$ACTUAL" = "$EXPECTED_CHECKSUM" ]; then
        echo "$FILENAME already downloaded and verified."
        exit 0
    fi
fi

echo "Downloading $URL ..."
curl -fSL -o "$FILEPATH" "$URL"

ACTUAL=$(sha256sum "$FILEPATH" | awk '{print $1}')
if [ "$ACTUAL" != "$EXPECTED_CHECKSUM" ]; then
    echo "ERROR: Checksum mismatch for $FILENAME" >&2
    echo "  Expected: $EXPECTED_CHECKSUM" >&2
    echo "  Got:      $ACTUAL" >&2
    rm -f "$FILEPATH"
    exit 1
fi

echo "Download verified: $FILEPATH"
