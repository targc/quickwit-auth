# Quickwit with Nginx Authentication Proxy

Simple Docker container that adds Basic HTTP Authentication to Quickwit using nginx reverse proxy.

## Files

- `Dockerfile` - Builds from `quickwit/quickwit:latest` and adds nginx
- `nginx.conf` - Reverse proxy configuration with authentication
- `entrypoint.sh` - Starts both nginx and Quickwit services

## Usage

Paste GCP Service Account file into ./tmp/sa-key.json

### Run
```bash
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

### Test
```bash
# Without auth (should get 401)
curl 'http://localhost:7280/api/v1/stackoverflow-schemaless/search?query='

# With auth (should work)
curl -u 'quickwit:password' 'http://localhost:7280/api/v1/stackoverflow-schemaless/search?query='
```

### Test with mock data

```bash
curl -XPOST -H 'Content-Type: application/yaml' -u 'quickwit:password' 'http://localhost:7280/api/v1/indexes' --data-binary @demo-data/stackoverflow-schemaless-config.yaml

curl -XPOST -H 'Content-Type: application/json' -u 'quickwit:password' 'http://localhost:7280/api/v1/stackoverflow-schemaless/ingest?commit=force' --data-binary @demo-data/stackoverflow.posts.transformed-10000.json

curl -u 'quickwit:password' 'http://localhost:7280/api/v1/stackoverflow-schemaless/search?query='
```

## Environment Variables

- `QUICKWIT_USERNAME` - Username for Basic Auth (optional, defaults to `admin`)
- `QUICKWIT_PASSWORD` - Password for Basic Auth (optional, defaults to `admin`)

## Architecture

- Single container running both nginx and Quickwit
- nginx listens on port 80, proxies to Quickwit on localhost:7280
- Basic HTTP authentication protects all endpoints
- 100% Quickwit API compatibility preserved
