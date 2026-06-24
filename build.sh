#!/bin/bash
#
# Build the upstream Prometheus node_exporter from source using the Go
# toolchain available on PATH (pinned via the .go-version file in CI).
#
# The node_exporter version is taken from the VERSION file (the part before
# the packaging-revision suffix). The matching upstream git tag is cloned and
# built with promu, exactly as upstream does, so the resulting binary reports
# the correct version and revision via `node_exporter --version` while being
# compiled with our (newer) Go toolchain.
#
# Usage: ./build.sh [--output-dir DIR]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(sed 's/-.*//' "$SCRIPT_DIR/VERSION")
REPO="https://github.com/prometheus/node_exporter"
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

if ! command -v go >/dev/null 2>&1; then
    echo "ERROR: go toolchain not found on PATH" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
# Resolve to an absolute path: we cd into the source tree below, so a relative
# --output-dir (e.g. "build" from the Makefile) must not be interpreted there.
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

SRC_DIR="$(mktemp -d)"
trap 'rm -rf "$SRC_DIR"' EXIT

echo "Cloning node_exporter v${VERSION} ..."
git clone --depth 1 --branch "v${VERSION}" "$REPO" "$SRC_DIR/node_exporter"
cd "$SRC_DIR/node_exporter"

# Bump the golang.org/x/* supplementary modules to their latest patched
# releases before building. A latest-Go rebuild fixes Go stdlib CVEs; bumping
# these modules also clears the remaining dependency CVEs reported by scanners.
# Set PATCH_DEPS=0 to build the pristine upstream sources instead.
if [ "${PATCH_DEPS:-1}" != "0" ]; then
    XMODS=$(go list -m -f '{{.Path}}' all | grep '^golang.org/x/' || true)
    if [ -n "$XMODS" ]; then
        echo "Bumping dependencies to latest patched releases:"
        echo "$XMODS" | sed 's/^/  /'
        # shellcheck disable=SC2086
        go get -u $XMODS
        go mod tidy
    fi
fi

echo "Building node_exporter v${VERSION} with $(go version)"
make common-build

cp "$SRC_DIR/node_exporter/node_exporter" "$OUTPUT_DIR/node_exporter"
cp "$SRC_DIR/node_exporter/LICENSE" "$OUTPUT_DIR/LICENSE"
cp "$SRC_DIR/node_exporter/NOTICE" "$OUTPUT_DIR/NOTICE"

echo "Built: $OUTPUT_DIR/node_exporter"
"$OUTPUT_DIR/node_exporter" --version
