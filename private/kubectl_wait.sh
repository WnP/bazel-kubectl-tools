#!/bin/bash
# kubectl_wait.sh - Wait for a Kubernetes resource condition with retry logic
#
# Usage: kubectl_wait.sh <kubectl_path> <timeout> <interval> <resource> <condition> [kubectl_args...]

set -euo pipefail

KUBECTL="$1"
TIMEOUT="$2"
INTERVAL="$3"
RESOURCE="$4"
CONDITION="$5"
shift 5
KUBECTL_ARGS=("$@")

elapsed=0
echo "Waiting for $RESOURCE to exist and have $CONDITION (timeout: ${TIMEOUT}s)..."

while [ $elapsed -lt $TIMEOUT ]; do
    # Check if resource exists
    if "$KUBECTL" get "$RESOURCE" "${KUBECTL_ARGS[@]}" >/dev/null 2>&1; then
        # Resource exists, try to wait for condition
        if "$KUBECTL" wait --for="$CONDITION" "$RESOURCE" "${KUBECTL_ARGS[@]}" --timeout=5s 2>/dev/null; then
            echo "Success: $RESOURCE has $CONDITION"
            exit 0
        fi
    fi

    echo "Waiting... (${elapsed}s elapsed)"
    sleep "$INTERVAL"
    elapsed=$((elapsed + INTERVAL))
done

echo "Timeout: $RESOURCE did not reach $CONDITION within ${TIMEOUT}s"
exit 1
