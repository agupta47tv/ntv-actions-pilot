#!/usr/bin/env bash
# Sample script for ShellCheck in CI — no secrets, no production logic.
set -euo pipefail

usage() {
    echo "Usage: $0 [--dry-run]"
    exit 0
}

dry_run=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) dry_run=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

project="${PROJECT_NAME:-NTVBE_master}"
target="${TARGET_NAME:-ntv-mv5}"

if [[ "$dry_run" == true ]]; then
    echo "Dry run: would validate project=${project} target=${target}"
    exit 0
fi

if [[ -z "$project" || -z "$target" ]]; then
    echo "PROJECT_NAME and TARGET_NAME must be set" >&2
    exit 1
fi

echo "OK: project=${project} target=${target}"
