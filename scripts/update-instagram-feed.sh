#!/bin/sh
set -eu

FEED_PATH="${INSTAGRAM_FEED_PATH:-/usr/share/nginx/html/instagram-feed.json}"
TOKEN_CLEAN="IGAAc8SVTWu1NBZAGExWFNoOVM0bktYVHlsOEU5S1FtaDR6M2JIcUJ0eUZAUcHNpMHlRdUhYRVFQdXhQTzM5Y19mR21lbnN5OGo4TUUwZAWNRNmNlVGprTFFHMWhpVDFwTzREUkJ6ZADhwTkl1R3R0SkEwSU5OWE1BVHF4ZA2VDSmlLZAwZDZD"
API_URL="https://graph.instagram.com/me/media?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp&limit=12&access_token=${TOKEN_CLEAN}"
HEADER_FILE="$(mktemp)"
BODY_FILE="$(mktemp)"
SANITIZED_FILE="$(mktemp)"

cleanup() {
  rm -f "$HEADER_FILE" "$BODY_FILE" "$SANITIZED_FILE"
}
trap cleanup EXIT

HTTP_STATUS="$(curl -sS -L -D "$HEADER_FILE" -o "$BODY_FILE" -w "%{http_code}" "$API_URL")"

if [ "$HTTP_STATUS" -ge 400 ]; then
  echo "Instagram API retornou HTTP $HTTP_STATUS" >&2
  echo "Cabecalhos de resposta:" >&2
  sed -n '1,20p' "$HEADER_FILE" >&2
  echo "Corpo de resposta (primeiros 500 chars):" >&2
  head -c 500 "$BODY_FILE" >&2 || true
  echo >&2
  exit 1
fi

# Algumas respostas podem conter bytes de controle invalidos para JSON.
# Removemos todo intervalo 0x00-0x1F para evitar falhas de parse no jq.
LC_ALL=C tr -d '\000-\037' < "$BODY_FILE" > "$SANITIZED_FILE"

if ! jq -e '.' "$SANITIZED_FILE" > /dev/null 2>&1; then
  echo "Resposta da API do Instagram nao eh um JSON valido apos limpeza." >&2
  echo "Cabecalhos de resposta:" >&2
  sed -n '1,20p' "$HEADER_FILE" >&2
  echo "Corpo sanitizado (primeiros 500 chars):" >&2
  head -c 500 "$SANITIZED_FILE" >&2 || true
  echo >&2
  exit 1
fi

if jq -e '.error' "$SANITIZED_FILE" > /dev/null; then
  echo "Erro retornado pela API do Instagram:" >&2
  jq '.' "$SANITIZED_FILE" >&2
  exit 1
fi

POSTS_JSON="$(jq '{
  updatedAt: (now | todateiso8601),
  source: "instagram_graph_api",
  items: (
    [.data[] | {
      id: .id,
      caption: (.caption // ""),
      media_type: .media_type,
      image: (if .media_type == "VIDEO" then (.thumbnail_url // .media_url) else .media_url end),
      media_url: .media_url,
      thumbnail_url: .thumbnail_url,
      permalink: .permalink,
      timestamp: .timestamp
    }] | .[:4]
  )
}' "$SANITIZED_FILE")"

printf $POSTS_JSON

# Use printf instead of echo to avoid escape-sequence interpretation corrupting JSON.
ITEMS_COUNT="$(printf '%s' "$POSTS_JSON" | jq '.items | length')"
if [ "$ITEMS_COUNT" -lt 1 ]; then
  echo "Nenhum post encontrado na resposta da API." >&2
  exit 1
fi

mkdir -p "$(dirname "$FEED_PATH")"
TMP_FILE="$(mktemp)"
printf '%s\n' "$POSTS_JSON" > "$TMP_FILE"
chmod 0644 "$TMP_FILE"
mv "$TMP_FILE" "$FEED_PATH"
chmod 0644 "$FEED_PATH"

echo "Feed do Instagram atualizado com ${ITEMS_COUNT} post(s) em $FEED_PATH"
