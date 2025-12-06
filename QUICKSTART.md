# GitLab Quick Start Guide

Get GitLab running in 5 minutes! 🚀

## Prerequisites

- Docker & Docker Compose installed
- 4GB+ RAM available
- 10GB+ disk space

## Step 1: Configure (1 minute)

```bash
# Copy environment template
cp .env.sample .env

# Edit hostname and password (optional)
nano .env
```

**Minimum required changes in `.env`:**
- `GITLAB_HOSTNAME` - Set to your hostname (default: `gitlab.local`)
- `GITLAB_ROOT_PASSWORD` - Set a strong password (min 8 chars)

## Step 2: Add Hostname (30 seconds)

Add to `/etc/hosts`:

```bash
echo "127.0.0.1 gitlab.local" | sudo tee -a /etc/hosts
```

Or use your actual hostname if on a server.

## Step 3: Start GitLab (30 seconds)

```bash
# Using Make (recommended)
make up

# Or using Docker Compose directly
docker compose up -d
```

## Step 4: Wait for Initialization (3-5 minutes)

GitLab needs time to initialize on first startup.

**Check status:**
```bash
# Watch logs
make logs

# Or check health
make health
```

Wait for: `gitlab Reconfigured!` message in logs.

## Step 5: Login (30 seconds)

1. Open: `http://gitlab.local:8080`
2. Username: `root`
3. Password: From `.env` or run `make get-password`

**First time?** Change your password in: **User Settings** → **Password**

## Step 6: Register Runner (2 minutes)

**IMPORTANT: Create runner in UI first (GitLab 16.0+ requirement)**

1. Go to **Admin Area** → **CI/CD** → **Runners**
2. Click **New instance runner**
3. Configure:
   - Platform: **Linux**
   - Tags: `docker`, `linux`, `arm64`
   - Run untagged jobs: ✓ **Enable**
4. Click **Create runner**
5. Copy authentication token (starts with `glrt-`)

Then register:
```bash
make register-runner
```

Paste the token when prompted.

## Done! 🎉

Your GitLab is ready with:
- ✅ Web UI: `http://gitlab.local:8080`
- ✅ Container Registry: `gitlab.local:5050`
- ✅ Package Registry: Built-in (npm, PyPI, Maven, etc.)
- ✅ CI/CD Runner: Registered and ready

## Quick Commands

```bash
make help              # Show all commands
make logs              # View logs
make restart           # Restart services
make down              # Stop services
make backup            # Create backup
```

## Next Steps

1. **Create a project**: Click **New project** in GitLab UI
2. **Push code**: 
   ```bash
   git remote add origin http://gitlab.local:8080/your-group/your-project.git
   git push -u origin main
   ```
3. **Add CI/CD**: Copy `examples/.gitlab-ci.yml` to your project
4. **Use Container Registry**: See README.md for details
5. **Publish npm packages**: See README.md for details

## Troubleshooting

### GitLab not starting?
```bash
# Check logs
make logs-gitlab

# Check resources
docker stats
```

### Can't access GitLab?
- Check `/etc/hosts` has `127.0.0.1 gitlab.local`
- Check port 8080 is not in use: `lsof -i :8080`
- Wait longer - first start takes 3-5 minutes

### Forgot password?
```bash
# Get initial password
make get-password

# Or reset password
docker exec -it gitlab gitlab-rake 'gitlab:password:reset[root]'
```

### Runner not working?
```bash
# Check runner status
docker exec gitlab-runner gitlab-runner list

# Re-register
make register-runner
```

## Need More Help?

- Full documentation: See `README.md`
- GitLab docs: https://docs.gitlab.com/
- Issues: Check logs with `make logs`

---

**Pro Tip:** Use `make help` to see all available commands!

