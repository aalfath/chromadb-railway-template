[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/chromadb?utm_medium=integration&utm_source=button&utm_campaign=chromadb)

# ChromaDB on Railway

This repo is the source of the **ChromaDB** template on Railway. It runs the official Chroma server, an open-source vector database for embeddings, with its data on a Railway volume and a token in front of the API.

- **Chroma:** `chromadb/chroma:1.5.9` (pinned by digest in the `Dockerfile`)
- **Proxy:** Caddy 2.11.9 (`caddy:2.11.9`, pinned by digest), copied into the same image
- **Data:** a volume mounted at `/data` (`chroma.sqlite3` plus the vector index folders)

## Why a proxy?

Chroma 1.x has no built-in authentication: anyone who can reach the server can read, write or delete every collection. This template starts Chroma on `127.0.0.1` inside the container and puts a small Caddy proxy on the public `PORT`. The proxy forwards a request only when it carries the token, in either header that Chroma's clients support:

- `X-Chroma-Token: <token>`
- `Authorization: Bearer <token>`

Requests without the right token get `401`. `/api/v2/heartbeat` and `/api/v2/version` stay open, because Railway's health check uses the heartbeat. CORS preflight (`OPTIONS`) requests also pass through, because browsers never send credentials on them.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `CHROMA_AUTH_TOKEN` | generated (`${{secret(48)}}`, letters and digits) | The API token. Clients must send it on every request. At least 16 characters from `A-Z a-z 0-9 . _ ~ + / = -`; the server refuses to start without it |
| `PORT` | `8000` | Port the proxy listens on (the Railway domain points here) |

Optional, not set by the template:

| Variable | Default | What it does |
|---|---|---|
| `CHROMA_ALLOW_RESET` | `false` | Set to `true` to allow `client.reset()`, which deletes everything |
| `CHROMA_CORS_ALLOW_ORIGINS` | empty | Comma-separated origins for browser apps, for example `https://app.example.com` |
| `CHROMA_PERSIST_PATH` | `/data` | Data directory (keep it on the volume) |
| `CHROMA_INTERNAL_PORT` | `8001` | Port Chroma listens on inside the container |

## Connecting

Python (`pip install chromadb` or the thin `chromadb-client`):

```python
import chromadb

client = chromadb.HttpClient(
    host="YOUR-APP.up.railway.app",
    port=443,
    ssl=True,
    headers={"X-Chroma-Token": "YOUR-CHROMA_AUTH_TOKEN"},
)
print(client.heartbeat())
collection = client.get_or_create_collection("docs")
```

JavaScript / TypeScript (`npm install chromadb`):

```ts
import { ChromaClient } from "chromadb";

const client = new ChromaClient({
  host: "YOUR-APP.up.railway.app",
  port: 443,
  ssl: true,
  headers: { "X-Chroma-Token": process.env.CHROMA_AUTH_TOKEN! },
});
```

From another service in the same Railway project, use the private network instead of the public domain: `http://${{ChromaDB.RAILWAY_PRIVATE_DOMAIN}}:8000`, still with the token.

## Updates

This template builds from this repo. When a new version is merged to `main`, Railway shows everyone who deployed the template an "update available" notice, and they choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) before you update. Chroma keeps its data in `/data`, and the volume is kept across updates, but back up important collections before a major version change.

## Local run

```sh
docker build -t chroma-railway .
docker run -p 8000:8000 -v chroma-data:/data -e CHROMA_AUTH_TOKEN=change-me-to-a-long-token chroma-railway
curl -H "X-Chroma-Token: change-me-to-a-long-token" http://localhost:8000/api/v2/auth/identity
```
