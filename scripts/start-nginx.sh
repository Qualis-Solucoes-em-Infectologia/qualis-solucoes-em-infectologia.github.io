#!/bin/sh
set -eu

/usr/local/bin/update-instagram-feed.sh || echo "Falha na atualizacao inicial do feed do Instagram." >&2

REFRESH_SECONDS="${INSTAGRAM_REFRESH_SECONDS:-0}"
if [ "$REFRESH_SECONDS" -gt 0 ] 2>/dev/null; then
  (
    while true; do
      sleep "$REFRESH_SECONDS"
      /usr/local/bin/update-instagram-feed.sh || echo "Falha na atualizacao periodica do feed do Instagram." >&2
    done
  ) &
fi

exec nginx -g 'daemon off;'
