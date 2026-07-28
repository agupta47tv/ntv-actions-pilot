# NTV Actions Pilot

Personal GitHub.com sandbox for learning **GitHub Actions** alongside on-prem Jenkins and `git@10.67.254.66`.

**This is not production SCM.** Official repos stay on the internal Git server until a company GitHub org is approved.

## What runs today (GitHub-hosted runners)

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push / PR | Secret scan (gitleaks) + ShellCheck on `scripts/` |
| `trigger-jenkins.yml` | Manual only | Trigger `NTV_BUILD` via Jenkins API |

## Quick start

### 1. Create the GitHub repo (personal account)

On [github.com/new](https://github.com/new):

- Name: `ntv-actions-pilot`
- Visibility: **Private**
- Do **not** add README (this repo has one)

### 2. Push from this machine

```bash
cd /home/proximus2/cursorinstall/ntv-actions-pilot
git remote add origin git@github.com:YOUR_GITHUB_USER/ntv-actions-pilot.git
git push -u origin main
```

Replace `YOUR_GITHUB_USER` with your GitHub username.

### 3. Verify Actions

1. Open the repo on GitHub → **Actions**
2. Push a branch or open a PR — `CI` should run green
3. For Jenkins trigger: see below (requires network access to Jenkins)

## Jenkins trigger (optional, Phase 2)

The internal Jenkins URL (`http://10.67.254.53:8080`) is **not reachable from GitHub-hosted runners** on the public internet.

Choose one:

| Option | Setup |
|--------|--------|
| **A. Self-hosted runner** (recommended) | Install runner on `proximus2` or Jenkins network; use label `ntv-internal` in workflow |
| **B. Skip for now** | Use `ci.yml` only; keep triggering via `trigger_build.sh` locally |

### GitHub Secrets (only if using trigger workflow)

Repo → **Settings → Secrets and variables → Actions**:

| Secret | Value |
|--------|--------|
| `JENKINS_URL` | `http://10.67.254.53:8080` |
| `JENKINS_USER` | Jenkins username |
| `JENKINS_TOKEN` | Low-privilege API token (rotate often) |

Use a **pilot-only** token, not production admin credentials.

## What not to put in this repo

- Vault tokens, Artifactory tokens, signing keys
- Firmware binaries (`.bin`, `.sao`)
- Copies of `genbox_nte-profile` or client overlays without approval
- Hardcoded passwords or PEM files

## Local checks (before push)

```bash
# ShellCheck (if installed)
shellcheck scripts/*.sh

# Gitleaks (if installed)
gitleaks detect --source . --verbose
```

## Roadmap

1. **Now:** CI gates on personal repo (this pilot)
2. **Next:** Self-hosted runner on internal network
3. **Later:** Company GitHub org + migrate `utilities-scripts` / `jenkins_script_53`
4. **Production:** Jenkins remains until Actions parity is proven

## Related on-prem tools

- Jenkins: `NTV_BUILD` on `10.67.254.53:8080`
- Trigger script: `/tmp/jenkins_script_53/scripts/trigger_build.sh`
- Internal Git: `git@10.67.254.66`
