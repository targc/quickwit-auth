# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dockerized Quickwit search engine with an nginx reverse proxy that adds Basic HTTP Authentication. The architecture uses a single container running both nginx (port 80) and Quickwit (port 7280) with nginx proxying authenticated requests to Quickwit.

## Key Commands

### Build and Run
```bash
# Build the Docker image
docker build -t quickwit-auth .

# Run with Docker Compose (recommended)
docker-compose up

# Run manually with Docker
docker run \
  -p 7280:80 \
  -v quickwit_data_index:/quickwit/qwdata/indexes \
  -v ./quickwit.yaml:/quickwit/config/quickwit.yaml \
  -v ./tmp/sa-key.json:/quickwit/config/sa-key.json:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS="/quickwit/config/sa-key.json" \
  -e QUICKWIT_USERNAME=quickwit \
  -e QUICKWIT_PASSWORD=password \
  quickwit-auth \
  run --config /quickwit/config/quickwit.yaml
```

### Testing
```bash
# Test authentication (should return 401)
curl 'http://localhost:7280/api/v1/stackoverflow-schemaless/search?query='

# Test with credentials (should work)
curl -u 'quickwit:password' 'http://localhost:7280/api/v1/stackoverflow-schemaless/search?query='

# Ingest test data
curl -XPOST -H 'Content-Type: application/yaml' -u 'quickwit:password' \
  'http://localhost:7280/api/v1/indexes' \
  --data-binary @demo-data/stackoverflow-schemaless-config.yaml

curl -XPOST -H 'Content-Type: application/json' -u 'quickwit:password' \
  'http://localhost:7280/api/v1/stackoverflow-schemaless/ingest?commit=force' \
  --data-binary @demo-data/stackoverflow.posts.transformed-10000.json
```

## Architecture

### Container Architecture
- **Single container design**: nginx and Quickwit run together in one container
- **nginx** (port 80): Reverse proxy with Basic Auth, forwards to Quickwit on localhost:7280
- **Quickwit** (port 7280): Search engine, only accessible internally through nginx
- **entrypoint.sh**: Orchestrates startup of both services

### Configuration Files
- `nginx.conf`: Reverse proxy configuration with authentication and performance optimizations
- `entrypoint.sh`: Creates htpasswd from environment variables and starts both services
- `quickwit.yaml`: Quickwit configuration pointing to GCS storage
- `docker-compose.yml`: Production deployment configuration

### Authentication
- Uses Basic HTTP Authentication via nginx
- Credentials set via environment variables:
  - `QUICKWIT_USERNAME` (default: admin)
  - `QUICKWIT_PASSWORD` (default: admin)
- Auth credentials stored in `/etc/nginx/.htpasswd` generated on startup

### Storage Configuration
- Uses Google Cloud Storage (GCS) for data persistence
- Requires GCP Service Account key at `./tmp/sa-key.json`
- Index data stored in `gs://quickwit-demo/indexes/`

## Development Notes

- The container runs as root to manage nginx, which is acceptable for this use case
- nginx configuration is optimized for high-bandwidth operations and large requests
- All Quickwit API endpoints are protected by authentication
- The project includes demo data for testing the search functionality