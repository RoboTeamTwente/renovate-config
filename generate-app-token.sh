#!/bin/sh -eu

encode_jwt_part() {
  openssl base64 | tr +/ -_ | tr -d '=\n'
}

issued_at=$(date +%s -d '1 minute ago')
expire_at=$(date +%s -d '5 minutes')

printf >&2 'Issued at: %s\nExpire at: %s\n' "$issued_at" "$expire_at"

header=$(jo alg=RS256 typ=JWT | encode_jwt_part)
payload=$(jo iat="$issued_at" exp="$expire_at" iss="$CLIENT_ID" | encode_jwt_part)
signature=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -sign <(printf '%s' "$PRIVATE_KEY") | encode_jwt_part)
jwt=$(printf '%s.%s.%s' "$header" "$payload" "$signature")

installation_id=$(gh api "$SCOPE"/installation -H "Authorization: Bearer $jwt" -q .id)
printf >&2 'Installation ID: %s\n' "$installation_id"

token=$(gh api app/installations/"$installation_id"/access_tokens -X POST -H "Authorization: Bearer $jwt" -q .token)

printf '%s' "$token"
