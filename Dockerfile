# ChromaDB for Railway: the official Chroma server behind a small token-checking proxy.
# Chroma 1.x has no built-in authentication, so Caddy (copied from the official image)
# listens on $PORT and only forwards requests that carry CHROMA_AUTH_TOKEN.
FROM caddy:2.11.9@sha256:4e2425f6009577e7c651010f16679c28f7d12df3e7b1914f941a7a3370746b3c AS caddy

FROM chromadb/chroma:1.5.9@sha256:1e0b73a187a28757c572acba508c46f48c9e8b0acaf5c20e6d95cdedce1acdf6

COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY Caddyfile /etc/chroma-proxy/Caddyfile
COPY start.sh /usr/local/bin/railway-chroma-start
RUN chmod 0755 /usr/local/bin/railway-chroma-start

ENV PORT=8000
EXPOSE 8000
VOLUME ["/data"]

ENTRYPOINT ["dumb-init", "--", "/usr/local/bin/railway-chroma-start"]
CMD []
