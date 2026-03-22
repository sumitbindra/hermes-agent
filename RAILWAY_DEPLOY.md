# Hermes Agent — Railway Deployment (Self-Hosted Fork)

Deploy your own fork of [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) on Railway with persistent state.

## Setup Steps

### 1. Fork the repo

```bash
# Fork NousResearch/hermes-agent on GitHub, then:
git clone --recurse-submodules https://github.com/YOUR_USERNAME/hermes-agent.git
cd hermes-agent
```

### 2. Add the deployment files

Copy `Dockerfile` and `entrypoint.sh` into the repo root:

```bash
# Copy the two files into your fork's root directory
chmod +x entrypoint.sh
git add Dockerfile entrypoint.sh
git commit -m "Add Railway deployment config"
git push origin main
```

### 3. Create the Railway service

1. Go to [railway.com](https://railway.com) → your project
2. Click **New Service** → **GitHub Repo** → select your fork
3. Railway auto-detects the Dockerfile

### 4. Add a persistent volume

1. In the service settings, go to **Volumes**
2. Mount path: `/data`
3. Size: 1–5 GB is plenty to start (memories, skills, config)

### 5. Set environment variables

In the service **Variables** tab, add:

#### Required — LLM Provider (at least one)

| Variable | Example |
|---|---|
| `OPENROUTER_API_KEY` | `sk-or-v1-...` |
| `ANTHROPIC_API_KEY` | `sk-ant-...` |
| `OPENAI_API_KEY` | `sk-...` |

#### Required — Messaging Platform (at least one)

| Variable | Example |
|---|---|
| `TELEGRAM_BOT_TOKEN` | `123456:ABC-DEF...` |
| `DISCORD_BOT_TOKEN` | `MTIz...` |
| `SLACK_BOT_TOKEN` | `xoxb-...` |

#### Optional

| Variable | Default | Notes |
|---|---|---|
| `HERMES_MODEL` | Auto-detected from provider | e.g. `anthropic/claude-sonnet-4` |
| `TELEGRAM_ALLOWED_USERS` | *(empty = allow all)* | Comma-separated Telegram user IDs |
| `DISCORD_ALLOWED_USERS` | *(empty = allow all)* | Comma-separated Discord user IDs |
| `TERMINAL_BACKEND` | `local` | `local`, `docker`, `ssh`, `modal` |
| `HERMES_HOME` | `/data/.hermes` | Don't change unless you move the volume |
| `MESSAGING_CWD` | `/data/workspace` | Agent's working directory |

### 6. Deploy

Railway builds from the Dockerfile automatically on push. First boot takes ~2–3 minutes (installing deps). Subsequent boots reuse the config from the volume.

## How It Works

- **First boot**: `entrypoint.sh` validates env vars, writes `config.yaml` + `.env` to the persistent volume, then starts `hermes gateway`
- **Subsequent boots**: Reuses existing config. Memory, skills, and conversations persist across redeploys.
- **To regenerate config**: Delete the `/data/.hermes/.initialized` marker file (via Railway shell) and redeploy.

## Updating Your Fork

```bash
# Add upstream remote (one-time)
git remote add upstream https://github.com/NousResearch/hermes-agent.git

# Pull latest changes
git fetch upstream
git merge upstream/main
git push origin main
# Railway auto-deploys on push
```

## Cost Estimate (Pro Plan)

With your existing $20/mo Pro plan credit:
- **Idle gateway**: ~$5–8/mo (covered by credits)
- **Active usage**: ~$10–20/mo (mostly covered, minimal overage)
- **Volume storage**: ~$0.15/GB/mo (negligible)
- **LLM inference**: Billed separately by your provider (OpenRouter, Anthropic, etc.)

## Troubleshooting

**Container crashes on boot:**
Check Railway logs. Usually a missing env var — the entrypoint validates and prints which one is missing.

**Config changes not taking effect:**
The entrypoint only generates `config.yaml` on first boot. Either:
- Delete `/data/.hermes/.initialized` and redeploy, or
- Edit `config.yaml` directly via Railway shell: `railway shell` → `vi /data/.hermes/config.yaml`

**Submodule issues:**
If `mini-swe-agent` isn't building, make sure you cloned with `--recurse-submodules` or run `git submodule update --init` before pushing.
