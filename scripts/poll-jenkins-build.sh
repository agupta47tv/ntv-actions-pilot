#!/usr/bin/env bash
# Poll Jenkins NTV_BUILD until the latest matching build finishes or timeout.
#
# Required: JENKINS_URL, JENKINS_USER, JENKINS_TOKEN
# Optional: PROJECT_NAME, TARGET_NAME (filter displayName), TIMEOUT_SEC (default 14400)
set -euo pipefail

JOB_NAME="${JENKINS_JOB_NAME:-NTV_BUILD}"
TIMEOUT_SEC="${TIMEOUT_SEC:-14400}"
POLL_SEC="${POLL_SEC:-60}"
PROJECT_NAME="${PROJECT_NAME:-}"
TARGET_NAME="${TARGET_NAME:-}"

require_env() {
    [[ -n "${!1:-}" ]] || { echo "Missing env: $1" >&2; exit 1; }
}

require_env JENKINS_URL
require_env JENKINS_USER
require_env JENKINS_TOKEN

api() {
    curl -sf --user "${JENKINS_USER}:${JENKINS_TOKEN}" "$@"
}

echo "Waiting for Jenkins ${JOB_NAME} build to complete (timeout ${TIMEOUT_SEC}s)..."

START=$(date +%s)
BUILD_NUM=""

while true; do
    NOW=$(date +%s)
    if (( NOW - START > TIMEOUT_SEC )); then
        echo "TIMEOUT waiting for Jenkins build" >&2
        exit 1
    fi

    JSON=$(api "${JENKINS_URL}/job/${JOB_NAME}/lastBuild/api/json?tree=number,displayName,building,result,url" || true)
    if [[ -z "$JSON" ]]; then
        sleep "$POLL_SEC"
        continue
    fi

    DISPLAY=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('displayName',''))")
    BUILDING=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('building', True))")
    RESULT=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result') or 'IN_PROGRESS')")
    BUILD_NUM=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('number',''))")
    URL=$(echo "$JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('url',''))")

    if [[ -n "$PROJECT_NAME" && "$DISPLAY" != *"$PROJECT_NAME"* ]]; then
        echo "Last build #$BUILD_NUM ($DISPLAY) does not match PROJECT_NAME=$PROJECT_NAME — waiting..."
        sleep "$POLL_SEC"
        continue
    fi
    if [[ -n "$TARGET_NAME" && "$DISPLAY" != *"$TARGET_NAME"* ]]; then
        echo "Last build #$BUILD_NUM ($DISPLAY) does not match TARGET_NAME=$TARGET_NAME — waiting..."
        sleep "$POLL_SEC"
        continue
    fi

    echo "Build #$BUILD_NUM $DISPLAY — building=$BUILDING result=$RESULT"

    if [[ "$BUILDING" == "False" || "$BUILDING" == "false" ]]; then
        echo "URL: $URL"
        if [[ "$RESULT" == "SUCCESS" ]]; then
            echo "Jenkins build SUCCESS"
            exit 0
        fi
        echo "Jenkins build finished with result: $RESULT" >&2
        exit 1
    fi

    sleep "$POLL_SEC"
done
