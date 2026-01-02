# Tracker

A modern BitTorrent tracker built with Rails 8.1, featuring:
- BitTorrent announce/scrape endpoints for peer discovery
- GraphQL API with JWT authentication for user and torrent management
- Torrent categorization system
- Real-time statistics tracking
- Automated peer cleanup and stats updates via background jobs

> **Note:** This is a toy project created to get back into Ruby development after more than a year away from Ruby coding. It is **not production-ready** and is intended for learning and experimentation purposes only.

## Prerequisites
- Ruby 4.0.0 and Bundler
- PostgreSQL 16+ and Redis 7 (docker-compose.yml provides both)
- `SECRET_KEY_BASE` (or Rails credentials) for JWT signing
- `DATABASE_*` environment variables to override local DB defaults

## Quick start (local)
1) Install gems: `bundle install`
2) Boot services: `docker compose up -d postgres redis`
3) Prepare the DB: `bin/rails db:setup`
4) Start the app: `bin/rails server` (or `bin/dev` for development with auto-reload)
5) Run background jobs: `bin/rails solid_queue:start` (or use `bin/jobs` for recurring jobs)

## Development
Run the full development environment:
```bash
docker compose up
```

## Production Deployment
The project includes Docker and Kamal configuration for production deployment.

Build and run with Docker:
```bash
docker compose -f docker-compose.prod.yml up -d
```

Ensure these environment variables are set:
- `SECRET_KEY_BASE`
- `DATABASE_URL`
- `REDIS_URL`

## Tests
- `bundle exec rspec`

## Tracker HTTP API
BitTorrent clients use these endpoints for peer discovery and statistics.

### Announce
`GET /announce`

**Required parameters:**
- `info_hash` - Torrent info hash (40-character hex or 20-byte raw)
- `peer_id` - Unique peer identifier (20 bytes)
- `port` - Client listening port
- `uploaded` - Total bytes uploaded
- `downloaded` - Total bytes downloaded
- `left` - Bytes remaining to download
- `user_id` - User ID for authentication

**Optional parameters:**
- `event` - One of: `started`, `completed`, `stopped`

**Response:** Bencoded dictionary with peer list and tracker interval

Example:
```bash
curl "http://localhost:3000/announce?info_hash=0123456789abcdef0123456789abcdef01234567&peer_id=ABCDEFGHIJKLMNOPQRST&port=6881&uploaded=0&downloaded=0&left=12345&event=started&user_id=1"
```

### Scrape
`GET /scrape`

**Parameters:**
- `info_hash` - One or multiple info hashes to query

**Response:** Bencoded dictionary with stats (seeders, leechers, completed) per torrent

Example:
```bash
curl "http://localhost:3000/scrape?info_hash=0123456789abcdef0123456789abcdef01234567"
```

## GraphQL API
GraphQL endpoint for managing users, torrents, and categories.

- **Endpoint:** `POST /graphql`
- **Authentication:** `Authorization: Bearer <JWT_token>`
- **Introspection:** Available in development mode for exploring the schema

Refer to the GraphQL schema introspection or the source files in `app/graphql/` for detailed documentation on each operation.

## Background jobs
The application uses Solid Queue for background job processing. See `app/jobs/` for individual job documentation.

**Job Management:**
```bash
# Start job worker
bin/rails solid_queue:start

# Run jobs with recurring schedule
bin/jobs

# Monitor jobs
bin/rails solid_queue:status
```

Recurring job schedule is configured in `config/recurring.yml`.

## Security & Testing
**Code quality tools:**
```bash
# Run test suite
bundle exec rspec

# Security audit
bin/brakeman
bin/bundler-audit

# Code style
bin/rubocop

# Full CI check
bin/ci
```

## License
See LICENSE file for details.

## Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Run the CI checks: `bin/ci`
5. Submit a pull request
