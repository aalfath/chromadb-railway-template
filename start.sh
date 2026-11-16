#!/usr/bin/env bash
# Starts Chroma on localhost and the token-checking Caddy proxy on $PORT.
# If either process exits, the container exits so Railway restarts it.
set -euo pipefail

export PORT="${PORT:-8000}"
export CHROMA_INTERNAL_PORT="${CHROMA_INTERNAL_PORT:-8001}"
CHROMA_PERSIST_PATH="${CHROMA_PERSIST_PATH:-/data}"
CHROMA_ALLOW_RESET="${CHROMA_ALLOW_RESET:-false}"

if [[ -z "${CHROMA_AUTH_TOKEN:-}" ]]; then
  echo "CHROMA_AUTH_TOKEN is empty. Refusing to start an unprotected Chroma server." >&2
  exit 1
fi
if [[ ! "${CHROMA_AUTH_TOKEN}" =~ ^[A-Za-z0-9._~+/=-]{16,}$ ]]; then
  echo "CHROMA_AUTH_TOKEN must be at least 16 characters from A-Z a-z 0-9 . _ ~ + / = -" >&2
  exit 1
fi
if [[ "${PORT}" == "${CHROMA_INTERNAL_PORT}" ]]; then
  echo "PORT and CHROMA_INTERNAL_PORT must differ." >&2
  exit 1
fi

mkdir -p "${CHROMA_PERSIST_PATH}"

CONFIG=/tmp/chroma-config.yaml
{
  echo "persist_path: \"${CHROMA_PERSIST_PATH}\""
  echo "listen_address: \"127.0.0.1\""
  echo "port: ${CHROMA_INTERNAL_PORT}"
  echo "allow_reset: ${CHROMA_ALLOW_RESET}"
  if [[ -n "${CHROMA_CORS_ALLOW_ORIGINS:-}" ]]; then
    printf 'cors_allow_origins: ['
    IFS=',' read -ra origins <<< "${CHROMA_CORS_ALLOW_ORIGINS}"
    sep=""
    for o in "${origins[@]}"; do
      o="${o// /}"
      [[ -n "$o" ]] && printf '%s"%s"' "$sep" "$o" && sep=", "
    done
    echo ']'
  fi
} > "${CONFIG}"

echo "Starting the Chroma server with data in ${CHROMA_PERSIST_PATH}; proxy on port ${PORT}"
chroma run "${CONFIG}" &
chroma_pid=$!

caddy run --config /etc/chroma-proxy/Caddyfile --adapter caddyfile &
caddy_pid=$!

set +e
wait -n "${chroma_pid}" "${caddy_pid}"
status=$?
echo "A process exited (status ${status}); stopping the container." >&2
kill "${chroma_pid}" "${caddy_pid}" 2>/dev/null
wait
# Always exit non-zero here, so Railway's ON_FAILURE restart policy brings the service back.
[[ "${status}" -eq 0 ]] && status=1
exit "${status}"
