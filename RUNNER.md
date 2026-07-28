# Self-hosted GitHub Actions runner (proximus2)

Runner connects **GitHub Actions** to your **internal network** (Jenkins at `10.67.254.53`).

## Labels (must match workflows)

| Label | Set by |
|-------|--------|
| `self-hosted` | Automatic |
| `linux` | `./config.sh --labels` |
| `ntv-internal` | `./config.sh --labels` |

Workflows using this runner:

- `.github/workflows/runner-smoke.yml`
- `.github/workflows/trigger-jenkins.yml`

## One-time setup

### 1. Get a registration token (expires ~1 hour)

Open:

**https://github.com/agupta47tv/ntv-actions-pilot/settings/actions/runners/new?arch=x64&os=linux**

Copy the token from the `./config.sh --token ...` command (long hex string).

### 2. Register and start (on proximus2)

```bash
cd /home/proximus2/cursorinstall/ntv-actions-pilot
chmod +x scripts/install-github-runner.sh

GITHUB_RUNNER_TOKEN='PASTE_TOKEN_HERE' ./scripts/install-github-runner.sh
```

Runner files live in `/home/proximus2/actions-runner`.

### 3. Verify on GitHub

**Settings → Actions → Runners** — runner `proximus2-ntv` should show **Idle** (green).

### 4. Run smoke test

**Actions → Runner smoke test → Run workflow**

All steps should pass (hostname, Jenkins HTTP 200, sample script).

### 5. Jenkins secrets (for trigger workflow)

Repo **Settings → Secrets and variables → Actions → New repository secret**:

| Name | Example |
|------|---------|
| `JENKINS_URL` | `http://10.67.254.53:8080` |
| `JENKINS_USER` | Jenkins username |
| `JENKINS_TOKEN` | API token (pilot-only, rotate often) |

Then: **Actions → Trigger Jenkins (manual)** → `dry_run: true` first.

## Service management

```bash
cd /home/proximus2/actions-runner
sudo ./svc.sh status
sudo ./svc.sh stop
sudo ./svc.sh start
```

## Remove / re-register

```bash
cd /home/proximus2/actions-runner
sudo ./svc.sh stop || true
sudo ./svc.sh uninstall || true
./config.sh remove --token REMOVAL_TOKEN
```

Removal token: **Settings → Actions → Runners → runner → Remove** (GitHub shows token).

## Security notes

- Runner executes arbitrary workflow code from GitHub — use **private repo only** and trust PR authors.
- Do not store Vault tokens in repo secrets longer than needed; prefer pilot Jenkins token with minimal scope.
- Runner user: `proximus2` (same as daily DevOps shell).
