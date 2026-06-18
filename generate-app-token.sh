#!/bin/sh -eu

encode_jwt_part() {
  openssl base64 | tr +/ -_ | tr -d '=\n'
}

api() {
  local endpoint=$1
  shift
  curl -sL https://api.github.com/"$endpoint" "$@" \
    -H 'Accept: application/vnd.github+json' \
    -H "Authorization: Bearer $jwt" \
    -H 'X-GitHub-Api-Version: 2026-03-10'
}

now=$(date +%s)
issued_at=$(( now - 60 ))
expire_at=$(( now + 600 ))

printf >&2 'Issued at: %s\nExpire at: %s\n' "$issued_at" "$expire_at"

header=$(jo alg=RS256 typ=JWT | encode_jwt_part)
payload=$(jo iat="$issued_at" exp="$expire_at" iss="$CLIENT_ID" | encode_jwt_part)
signature=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -sign <(printf '%s' "$PRIVATE_KEY") | encode_jwt_part)
jwt=$(printf '%s.%s.%s' "$header" "$payload" "$signature")

installation_id=$(api "$SCOPE"/installation | jq -r .id)
printf >&2 'Installation ID: %s\n' "$installation_id"

token=$(api app/installations/"$installation_id"/access_tokens -X POST | jq -r .token)

printf '%s' "$token"
