#!/usr/bin/env bash
# Trigger Jenkins NTV_BUILD via REST API.
# Credentials from environment (GitHub Secrets in Actions, or Vault locally).
#
# Required env: JENKINS_URL, JENKINS_USER, JENKINS_TOKEN
# Optional: PROJECT_NAME, TARGET_NAME, TARGET_VERSION, SET_PROFILE, RUN_BUILD, etc.
set -euo pipefail

JOB_NAME="${JENKINS_JOB_NAME:-NTV_BUILD}"

require_env() {
    local name="$1"
    if [[ -z "${!name:-}" ]]; then
        echo "Missing required env: $name" >&2
        exit 1
    fi
}

require_env JENKINS_URL
require_env JENKINS_USER
require_env JENKINS_TOKEN

PROJECT_NAME="${PROJECT_NAME:-NTVBE_master}"
TARGET_NAME="${TARGET_NAME:-ntv-mv5}"
TARGET_VERSION="${TARGET_VERSION:-}"
PREBUILT_BASE_VERSION="${PREBUILT_BASE_VERSION:-}"
NEW_SPRINT="${NEW_SPRINT:-false}"
SET_PROFILE="${SET_PROFILE:-false}"
RUN_CREATE_EBUILD="${RUN_CREATE_EBUILD:-false}"
RUN_BUILD="${RUN_BUILD:-false}"
RUN_CHECK_PREBUILD="${RUN_CHECK_PREBUILD:-false}"
RUN_PUSH_EBUILD="${RUN_PUSH_EBUILD:-false}"
RUN_SCP_PREBUILD="${RUN_SCP_PREBUILD:-false}"
RUN_ABR_SECURITY="${RUN_ABR_SECURITY:-false}"
RUN_APPLY_SECURITY="${RUN_APPLY_SECURITY:-false}"
GIT_LOG_MODULE="${GIT_LOG_MODULE:-false}"
RUN_NOTIFY="${RUN_NOTIFY:-false}"
NOTIFY_AMIT="${NOTIFY_AMIT:-false}"
NOTIFY_AMIT_ONLY="${NOTIFY_AMIT_ONLY:-false}"

if [[ "${DRY_RUN:-false}" == true ]]; then
    echo "DRY RUN — would POST to ${JENKINS_URL}/job/${JOB_NAME}/buildWithParameters"
    echo "  PROJECT_NAME=${PROJECT_NAME} TARGET_NAME=${TARGET_NAME} TARGET_VERSION=${TARGET_VERSION:-auto}"
    echo "  SET_PROFILE=${SET_PROFILE} RUN_BUILD=${RUN_BUILD} RUN_APPLY_SECURITY=${RUN_APPLY_SECURITY}"
    exit 0
fi

echo "Triggering ${JOB_NAME}..."
echo "  PROJECT_NAME=${PROJECT_NAME} TARGET_NAME=${TARGET_NAME} TARGET_VERSION=${TARGET_VERSION:-auto}"
echo "  SET_PROFILE=${SET_PROFILE} RUN_CREATE_EBUILD=${RUN_CREATE_EBUILD} RUN_BUILD=${RUN_BUILD}"
echo "  RUN_CHECK_PREBUILD=${RUN_CHECK_PREBUILD} RUN_PUSH_EBUILD=${RUN_PUSH_EBUILD}"
echo "  RUN_SCP_PREBUILD=${RUN_SCP_PREBUILD} RUN_APPLY_SECURITY=${RUN_APPLY_SECURITY} RUN_NOTIFY=${RUN_NOTIFY}"

COOKIE_JAR="$(mktemp)"
trap 'rm -f "$COOKIE_JAR"' EXIT

CRUMB="$(
    curl -sf -c "$COOKIE_JAR" --user "${JENKINS_USER}:${JENKINS_TOKEN}" \
        "${JENKINS_URL}/crumbIssuer/api/json" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])"
)"

CRUMB_FIELD="$(
    curl -sf -c "$COOKIE_JAR" --user "${JENKINS_USER}:${JENKINS_TOKEN}" \
        "${JENKINS_URL}/crumbIssuer/api/json" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('crumbRequestField','Jenkins-Crumb'))"
)"

POST_DATA="PROJECT_NAME=${PROJECT_NAME}"
POST_DATA+="&TARGET_NAME=${TARGET_NAME}"
POST_DATA+="&TARGET_VERSION=${TARGET_VERSION}"
POST_DATA+="&PREBUILT_BASE_VERSION=${PREBUILT_BASE_VERSION}"
POST_DATA+="&NEW_SPRINT=${NEW_SPRINT}"
POST_DATA+="&SET_PROFILE=${SET_PROFILE}"
POST_DATA+="&RUN_CREATE_EBUILD=${RUN_CREATE_EBUILD}"
POST_DATA+="&RUN_BUILD=${RUN_BUILD}"
POST_DATA+="&RUN_CHECK_PREBUILD=${RUN_CHECK_PREBUILD}"
POST_DATA+="&RUN_PUSH_EBUILD=${RUN_PUSH_EBUILD}"
POST_DATA+="&RUN_SCP_PREBUILD=${RUN_SCP_PREBUILD}"
POST_DATA+="&RUN_ABR_SECURITY=${RUN_ABR_SECURITY}"
POST_DATA+="&RUN_APPLY_SECURITY=${RUN_APPLY_SECURITY}"
POST_DATA+="&GIT_LOG_MODULE=${GIT_LOG_MODULE}"
POST_DATA+="&RUN_NOTIFY=${RUN_NOTIFY}"
POST_DATA+="&NOTIFY_AMIT=${NOTIFY_AMIT}"
POST_DATA+="&NOTIFY_AMIT_ONLY=${NOTIFY_AMIT_ONLY}"

HTTP_CODE="$(
    curl -sf -o /dev/null -w '%{http_code}' -b "$COOKIE_JAR" \
        --user "${JENKINS_USER}:${JENKINS_TOKEN}" \
        -H "${CRUMB_FIELD}: ${CRUMB}" \
        -X POST "${JENKINS_URL}/job/${JOB_NAME}/buildWithParameters" \
        --data-urlencode "PROJECT_NAME=${PROJECT_NAME}" \
        --data-urlencode "TARGET_NAME=${TARGET_NAME}" \
        --data-urlencode "TARGET_VERSION=${TARGET_VERSION}" \
        --data-urlencode "PREBUILT_BASE_VERSION=${PREBUILT_BASE_VERSION}" \
        --data-urlencode "NEW_SPRINT=${NEW_SPRINT}" \
        --data-urlencode "SET_PROFILE=${SET_PROFILE}" \
        --data-urlencode "RUN_CREATE_EBUILD=${RUN_CREATE_EBUILD}" \
        --data-urlencode "RUN_BUILD=${RUN_BUILD}" \
        --data-urlencode "RUN_CHECK_PREBUILD=${RUN_CHECK_PREBUILD}" \
        --data-urlencode "RUN_PUSH_EBUILD=${RUN_PUSH_EBUILD}" \
        --data-urlencode "RUN_SCP_PREBUILD=${RUN_SCP_PREBUILD}" \
        --data-urlencode "RUN_ABR_SECURITY=${RUN_ABR_SECURITY}" \
        --data-urlencode "RUN_APPLY_SECURITY=${RUN_APPLY_SECURITY}" \
        --data-urlencode "GIT_LOG_MODULE=${GIT_LOG_MODULE}" \
        --data-urlencode "RUN_NOTIFY=${RUN_NOTIFY}" \
        --data-urlencode "NOTIFY_AMIT=${NOTIFY_AMIT}" \
        --data-urlencode "NOTIFY_AMIT_ONLY=${NOTIFY_AMIT_ONLY}"
)"

if [[ "$HTTP_CODE" != "201" && "$HTTP_CODE" != "200" && "$HTTP_CODE" != "302" ]]; then
    echo "Jenkins trigger failed HTTP ${HTTP_CODE}" >&2
    exit 1
fi

echo "Jenkins build triggered (HTTP ${HTTP_CODE})"
echo "Queue: ${JENKINS_URL}/job/${JOB_NAME}/"
