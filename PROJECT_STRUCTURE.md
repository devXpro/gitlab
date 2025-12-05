# GitLab Docker Compose - Project Structure

## Overview

This is a complete, production-ready GitLab CE setup with Docker Compose, optimized for ARM64 architecture (Apple Silicon, Raspberry Pi, etc.).

## Features

✅ **GitLab CE** - Full-featured GitLab Community Edition  
✅ **Container Registry** - Docker image storage and management  
✅ **Package Registry** - npm, PyPI, Maven, NuGet, Composer, etc.  
✅ **GitLab Runner** - CI/CD with Docker executor  
✅ **Docker-in-Docker** - Build Docker images in pipelines  
✅ **Host Volumes** - Easy backup and migration  
✅ **ARM64 Native** - Optimized for Apple Silicon and ARM devices  
✅ **Production Ready** - Health checks, resource optimization, security best practices  

## Project Structure

```
.
├── docker-compose.yml          # Main Docker Compose configuration
├── .env.sample                 # Environment variables template
├── .gitignore                  # Git ignore rules
├── Makefile                    # Convenient commands (make up, make logs, etc.)
├── README.md                   # Full documentation
├── QUICKSTART.md               # 5-minute quick start guide
├── PROJECT_STRUCTURE.md        # This file
│
├── data/                       # Persistent data (gitignored)
│   ├── gitlab/
│   │   ├── config/            # GitLab configuration
│   │   ├── logs/              # GitLab logs
│   │   └── data/              # GitLab data (repos, uploads, etc.)
│   └── runner/
│       └── config/            # Runner configuration
│
├── scripts/                    # Helper scripts
│   ├── register-runner.sh     # Register GitLab Runner
│   └── get-root-password.sh   # Get initial root password
│
└── examples/                   # Example files
    ├── .gitlab-ci.yml         # Example CI/CD pipeline
    ├── Dockerfile             # Example Dockerfile
    ├── package.json           # Example npm package
    └── .dockerignore          # Docker ignore rules
```

## Services

### 1. GitLab CE (`gitlab`)
- **Image**: `gitlab/gitlab-ce:latest`
- **Ports**: 
  - `8080` - Web UI
  - `5050` - Container Registry
  - `2222` - SSH (Git operations)
- **Features**:
  - Container Registry enabled
  - Package Registry enabled (npm, PyPI, Maven, etc.)
  - GitLab Pages disabled (can be enabled)
  - Prometheus monitoring disabled (resource optimization)
  - Optimized Puma and Sidekiq settings

### 2. GitLab Runner (`gitlab-runner`)
- **Image**: `gitlab/gitlab-runner:alpine`
- **Executor**: Docker
- **Features**:
  - Docker socket mounted for building images
  - Privileged mode for Docker-in-Docker
  - Connected to gitlab-network
  - Auto-starts after GitLab is healthy

### 3. Docker-in-Docker (`dind`)
- **Image**: `docker:dind`
- **Purpose**: Secure Docker image building in CI/CD
- **Features**:
  - Privileged mode
  - TLS disabled for local development
  - Overlay2 storage driver
  - Persistent volume for Docker data

## Configuration Files

### docker-compose.yml
Main orchestration file with:
- Service definitions
- Network configuration
- Volume mappings
- Health checks
- Environment variables

### .env
Environment configuration (create from `.env.sample`):
- `GITLAB_HOSTNAME` - Your GitLab hostname
- `GITLAB_ROOT_PASSWORD` - Initial root password
- `GITLAB_HTTP_PORT` - Web UI port (default: 8080)
- `GITLAB_REGISTRY_PORT` - Container Registry port (default: 5050)
- `GITLAB_SSH_PORT` - SSH port (default: 2222)
- `TZ` - Timezone

### Makefile
Convenient commands:
- `make up` - Start services
- `make down` - Stop services
- `make logs` - View logs
- `make restart` - Restart services
- `make backup` - Create backup
- `make restore` - Restore from backup
- `make get-password` - Get root password
- `make register-runner` - Register runner
- `make health` - Check GitLab health

## Quick Start

```bash
# 1. Configure
cp .env.sample .env
nano .env

# 2. Add hostname to /etc/hosts
echo "127.0.0.1 gitlab.local" | sudo tee -a /etc/hosts

# 3. Start
make up

# 4. Wait 3-5 minutes for initialization
make logs

# 5. Access GitLab
open http://gitlab.local:8080

# 6. Register runner
make register-runner
```

## Data Persistence

All data is stored in host volumes under `./data/`:

- **GitLab config**: `./data/gitlab/config` → `/etc/gitlab`
- **GitLab logs**: `./data/gitlab/logs` → `/var/log/gitlab`
- **GitLab data**: `./data/gitlab/data` → `/var/opt/gitlab`
- **Runner config**: `./data/runner/config` → `/etc/gitlab-runner`
- **Docker data**: Named volume `dind-storage`

## Backup & Restore

### Backup
```bash
make backup
# Creates: gitlab-backup-YYYYMMDD-HHMMSS.tar.gz
```

### Restore
```bash
make restore BACKUP=gitlab-backup-YYYYMMDD-HHMMSS.tar.gz
```

## ARM64 Compatibility

All images support ARM64 architecture:
- ✅ `gitlab/gitlab-ce:latest` - Multi-arch (amd64, arm64)
- ✅ `gitlab/gitlab-runner:alpine` - Multi-arch (amd64, arm64, arm, s390x, ppc64le)
- ✅ `docker:dind` - Multi-arch (amd64, arm64, arm)

Tested on:
- Apple Silicon (M1/M2/M3)
- Raspberry Pi 4/5
- AWS Graviton

## Resource Requirements

**Minimum**:
- 4GB RAM
- 2 CPU cores
- 10GB disk space

**Recommended**:
- 8GB RAM
- 4 CPU cores
- 50GB+ disk space

## Security Notes

- Initial root password is auto-generated (get with `make get-password`)
- Change root password after first login
- TLS is disabled (use external nginx for production)
- Docker socket is mounted (required for Docker executor)
- Privileged mode is enabled for dind (required for building images)

## Next Steps

1. Read `QUICKSTART.md` for 5-minute setup
2. Read `README.md` for full documentation
3. Check `examples/` for CI/CD pipeline examples
4. Configure external nginx for TLS (production)
5. Set up backups (automated with cron)

## Support

- [GitLab Documentation](https://docs.gitlab.com/)
- [GitLab Forum](https://forum.gitlab.com/)
- [Docker Documentation](https://docs.docker.com/)

## License

GitLab CE is open source under the MIT License.

