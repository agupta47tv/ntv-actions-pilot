#!/usr/bin/env bash
# Register and start a self-hosted GitHub Actions runner for ntv-actions-pilot.
#
# Usage (registration token from GitHub UI — expires in ~1 hour):
#   GITHUB_RUNNER_TOKEN='XXXX' ./scripts/install-github-runner.sh
#
# Or with a fine-grained PAT (repo administration):
#   GITHUB_PAT='ghp_...' ./scripts/install-github-runner.sh
#
# GitHub UI: Repo → Settings → Actions → Runners → New self-hosted runner → Linux
set -euo pipefail

REPO_URL="${GITHUB_REPO_URL:-https://github.com/agupta47tv/ntv-actions-pilot}"
RUNNER_NAME="${RUNNER_NAME:-proximus2-ntv}"
RUNNER_LABELS="${RUNNER_LABELS:-linux,ntv-internal}"
RUNNER_DIR="${RUNNER_DIR:-/home/proximus2/actions-runner}"
RUNNER_VERSION="${RUNNER_VERSION:-2.336.0}"

red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
nc='\033[0m'

die() { echo -e "${red}ERROR: $*${nc}" >&2; exit 1; }
info() { echo -e "${green}$*${nc}"; }
warn() { echo -e "${yellow}$*${nc}"; }

need_root_for_service=false
if [[ "${INSTALL_SERVICE:-true}" == true ]]; then
    need_root_for_service=true
fi

fetch_registration_token() {
    if [[ -n "${GITHUB_RUNNER_TOKEN:-}" ]]; then
        echo "$GITHUB_RUNNER_TOKEN"
        return
    fi
    if [[ -n "${GITHUB_PAT:-}" ]]; then
        local repo_path
        repo_path="$(echo "$REPO_URL" | sed -E 's#https://github.com/##')"
        curl -sf -X POST \
            -H "Authorization: Bearer ${GITHUB_PAT}" \
            -H "Accept: application/vnd.github+json" \
            "https://api.github.com/repos/${repo_path}/actions/runners/registration-token" \
            | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])"
        return
    fi
    die "Set GITHUB_RUNNER_TOKEN (from GitHub UI) or GITHUB_PAT (repo admin)"
}

install_deps() {
    if command -v apt-get >/dev/null 2>&1; then
        warn "Checking runner dependencies (may prompt for sudo)..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq curl tar libicu70 liblttng-ust1 libkrb5-3 zlib1g 2>/dev/null \
            || sudo apt-get install -y -qq curl tar libicu66 liblttng-ust0 libkrb5-3 zlib1g
    fi
}

download_runner() {
    mkdir -p "$RUNNER_DIR"
    if [[ -f "${RUNNER_DIR}/config.sh" ]]; then
        info "Runner files already present in ${RUNNER_DIR}"
        return
    fi
    info "Downloading actions-runner v${RUNNER_VERSION}..."
    curl -sSL -o /tmp/actions-runner.tar.gz \
        "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
    tar xzf /tmp/actions-runner.tar.gz -C "$RUNNER_DIR"
    rm -f /tmp/actions-runner.tar.gz
}

configure_runner() {
    local token="$1"
    if [[ -f "${RUNNER_DIR}/.runner" ]]; then
        warn "Runner already configured (${RUNNER_DIR}/.runner exists). Skip config or remove dir first."
        return
    fi
    info "Configuring runner: name=${RUNNER_NAME} labels=${RUNNER_LABELS}"
    cd "$RUNNER_DIR"
    ./config.sh \
        --url "$REPO_URL" \
        --token "$token" \
        --name "$RUNNER_NAME" \
        --labels "$RUNNER_LABELS" \
        --unattended \
        --replace
}

install_service() {
    cd "$RUNNER_DIR"
    if [[ -f /etc/systemd/system/actions.runner.*.service ]]; then
        warn "Runner service already installed."
        return
    fi
    info "Installing systemd service (runs as ${USER})..."
    sudo ./svc.sh install "$USER"
    sudo ./svc.sh start
    sudo ./svc.sh status || true
}

print_next_steps() {
    cat <<EOF

${green}Runner setup complete.${nc}

Verify on GitHub:
  ${REPO_URL}/settings/actions/runners
  Expect: ${RUNNER_NAME} — Idle — labels: self-hosted, Linux, ${RUNNER_LABELS//,/, }

Test workflow:
  Actions → "Runner smoke test" → Run workflow

Jenkins trigger (after adding repo Secrets):
  JENKINS_URL, JENKINS_USER, JENKINS_TOKEN
  Actions → "Trigger Jenkins (manual)" → dry_run: true

EOF
}

main() {
    install_deps
    download_runner
    token="$(fetch_registration_token)"
    configure_runner "$token"
    if [[ "$need_root_for_service" == true ]]; then
        install_service
    else
        warn "Skipping service install (INSTALL_SERVICE=false). Start manually: cd ${RUNNER_DIR} && ./run.sh"
    fi
    print_next_steps
}

main "$@"
