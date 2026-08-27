#!/bin/bash
# Build and run the isolated Docker test environment for scrcpy-autostart.
#
# Usage:
#   ./test/test-in-docker.sh lint           # bash -n + shellcheck on every shell script
#   ./test/test-in-docker.sh shell          # interactive shell in the test environment
#   ./test/test-in-docker.sh <cmd> [args]   # run any command in the environment, e.g.:
#   ./test/test-in-docker.sh ./install-linux.sh
#   ./test/test-in-docker.sh apt-get install -y zenity
#
# Properties:
#   - The repo is mounted at /workspace, so tests exercise the local working
#     tree (never the possibly-stale main branch on GitHub).
#   - Every run uses a fresh --rm container: packages installed, $HOME state,
#     and /tmp contents never leak back onto the host.
#   - The container is headless (no display, no zenity/kdialog, no adb/scrcpy)
#     and runs as a non-root user with passwordless sudo.

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/.." && pwd)"
IMAGE="scrcpy-autostart-test"

if ! command -v docker >/dev/null 2>&1; then
    echo "error: docker is not installed or not in PATH" >&2
    exit 1
fi

usage() {
    sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

build() {
    docker build -q -t "$IMAGE" -f "$TEST_DIR/Dockerfile" "$REPO_ROOT" >/dev/null
}

LINT_SCRIPT='
fail=0
for f in *.sh bin/*.sh config/*.sh; do
    [ -f "$f" ] || continue
    if bash -n "$f"; then
        echo "OK   bash -n      $f"
    else
        echo "FAIL bash -n      $f"; fail=1
    fi
    if shellcheck "$f"; then
        echo "OK   shellcheck   $f"
    else
        echo "FAIL shellcheck   $f"; fail=1
    fi
done
exit $fail
'

case "$1" in
    lint)
        build
        docker run --rm -v "$REPO_ROOT:/workspace" -w /workspace "$IMAGE" bash -c "$LINT_SCRIPT"
        ;;
    shell)
        build
        docker run --rm -it -v "$REPO_ROOT:/workspace" -w /workspace "$IMAGE" bash
        ;;
    *)
        build
        docker run --rm -v "$REPO_ROOT:/workspace" -w /workspace "$IMAGE" "$@"
        ;;
esac
