# GitHub Actions pilot — push checklist

Local repo ready at: `/home/proximus2/cursorinstall/ntv-actions-pilot`

## Step 1 — GitHub SSH key (one time)

```bash
# Generate key (use your GitHub email)
ssh-keygen -t ed25519 -C "amit.gupta2@rsystems.com" -f ~/.ssh/id_ed25519_github -N ""

# Start agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github

# Print public key — add at https://github.com/settings/keys
cat ~/.ssh/id_ed25519_github.pub
```

Add to `~/.ssh/config`:

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes
```

Test:

```bash
ssh -T git@github.com
```

## Step 2 — Create private repo on GitHub

1. https://github.com/new
2. Name: `ntv-actions-pilot`
3. Private
4. Do not initialize with README

## Step 3 — Push

```bash
cd /home/proximus2/cursorinstall/ntv-actions-pilot
git remote add origin git@github.com:agupta47tv/ntv-actions-pilot.git
git push -u origin main
```

## Step 4 — Confirm CI

GitHub → repo → **Actions** → workflow **CI** should run on push (green).

## Step 5 — Jenkins trigger (later)

Only after installing a **self-hosted runner** on proximus2:

1. Repo → Settings → Actions → Runners → New self-hosted runner
2. Labels: `linux`, `ntv-internal`
3. Add Secrets: `JENKINS_URL`, `JENKINS_USER`, `JENKINS_TOKEN`
4. Actions → **Trigger Jenkins (manual)** → Run workflow (dry_run: true first)

## Local test (no GitHub)

```bash
cd /home/proximus2/cursorinstall/ntv-actions-pilot
./scripts/sample-check.sh --dry-run
DRY_RUN=true JENKINS_URL=http://10.67.254.53:8080 JENKINS_USER=x JENKINS_TOKEN=x \
  ./scripts/trigger-jenkins-api.sh
```

For real Jenkins trigger locally, load Vault first:

```bash
source /tmp/utilities-scripts/vault-load-secrets.sh jenkins
export PROJECT_NAME=NTVBE_master TARGET_NAME=ntv-mv5 DRY_RUN=true
./scripts/trigger-jenkins-api.sh
```
