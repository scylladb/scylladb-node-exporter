#!/usr/bin/env python3
#
# Create a relocatable tarball package for scylla-node-exporter.
# Usage: scripts/create-relocatable-package.py [--output DIR] [--arch ARCH]

import argparse
import os
import pathlib
import platform
import subprocess
import sys
import tarfile

def main():
    parser = argparse.ArgumentParser(description="Create scylla-node-exporter relocatable package")
    parser.add_argument("--output", default="build",
                        help="Output directory for the tarball (default: build)")
    parser.add_argument("--arch", default=platform.machine(),
                        help="Target architecture for the tarball name (default: host arch)")
    args = parser.parse_args()

    script_dir = pathlib.Path(__file__).resolve().parent.parent
    version_file = script_dir / "VERSION"
    version = version_file.read_text().strip().split("-")[0]

    build_dir = script_dir / "build"
    # Ship the unstripped binary so downstream consumers (e.g. the ScyllaDB
    # build) can strip it and extract debug info themselves, matching the
    # layout of the upstream node_exporter release tarball.
    binary = build_dir / "node_exporter"
    if not binary.exists():
        print(f"ERROR: {binary} not found. Run 'make build' first.", file=sys.stderr)
        sys.exit(1)

    output_dir = pathlib.Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    pkg_name = f"scylla-node-exporter-{version}"
    # Use Go-style arch names (amd64/arm64) and include the arch in the tarball
    # name so the per-arch builds do not collide when published to the same S3
    # prefix / GitHub release.
    go_arch = {"x86_64": "amd64", "aarch64": "arm64"}.get(args.arch, args.arch)
    tarball = output_dir / f"{pkg_name}.{go_arch}.tar.gz"

    print(f"Creating relocatable package: {tarball}")

    with tarfile.open(tarball, "w:gz") as tar:
        # Binary
        tar.add(str(binary), arcname=f"{pkg_name}/node_exporter")

        # Licenses (flat at the top level, matching upstream node_exporter)
        for name in ("LICENSE", "NOTICE"):
            path = build_dir / name
            if path.exists():
                tar.add(str(path), arcname=f"{pkg_name}/{name}")

        # Config files
        dist_dir = script_dir / "dist"
        configs = [
            ("sysconfig/scylla-node-exporter", "conf/scylla-node-exporter"),
            ("systemd/scylla-node-exporter.service", "systemd/scylla-node-exporter.service"),
            ("systemd/scylla-node-exporter.service.d/dependencies.conf",
             "systemd/scylla-node-exporter.service.d/dependencies.conf"),
            ("supervisor/scylla-node-exporter.sh", "supervisor/scylla-node-exporter.sh"),
        ]
        for src, dst in configs:
            path = dist_dir / src
            if path.exists():
                tar.add(str(path), arcname=f"{pkg_name}/{dst}")

        # install.sh
        install_sh = script_dir / "install.sh"
        if install_sh.exists():
            tar.add(str(install_sh), arcname=f"{pkg_name}/install.sh")

        # VERSION
        tar.add(str(version_file), arcname=f"{pkg_name}/VERSION")

    print(f"Created: {tarball}")
    print(f"Size: {tarball.stat().st_size} bytes")

if __name__ == "__main__":
    main()
