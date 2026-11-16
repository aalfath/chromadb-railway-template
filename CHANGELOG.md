# Changelog

## 1.5.9 (2026-11-16)

First release of the template.

- Chroma server 1.5.9 (`chromadb/chroma:1.5.9`, pinned by digest), data on a volume at `/data`.
- Token auth through a Caddy 2.11.9 proxy on `PORT` (Chroma 1.x has no built-in auth): send `CHROMA_AUTH_TOKEN` as `X-Chroma-Token` or `Authorization: Bearer`. `/api/v2/heartbeat` stays open for the health check.
- `client.reset()` is off unless `CHROMA_ALLOW_RESET=true`.
