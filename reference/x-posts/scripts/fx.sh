#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' 'Usage: fx.sh <post-url> [--json]' '       fx.sh --help' '' 'Read one public X post and its text, author, media, quote, and reply link.' 'Options:' '  --json  Print the full FxTwitter v2 JSON response.' '  --help  Show this help.'
}

if (( $# == 0 )); then usage; exit 0; fi
post_url=''
raw=false
for arg in "$@"; do
  case "$arg" in
    --help) usage; exit 0 ;;
    --json) raw=true ;;
    -*) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
    *)
      if [[ -n $post_url ]]; then printf 'Specify exactly one post URL.\n' >&2; exit 2; fi
      post_url=$arg
      ;;
  esac
done
if [[ -z $post_url ]]; then usage >&2; exit 2; fi

# Only the snowflake ID reaches the service; do not treat arbitrary URL components as API paths.
if [[ $post_url =~ ^https://(www\.)?(x\.com|twitter\.com)/[^/?#]+/status/([0-9]{2,20})([/?#].*)?$ ]]; then
  id=${BASH_REMATCH[3]}
else
  printf 'Expected an https://x.com/<handle>/status/<id> post URL.\n' >&2
  exit 2
fi

response=$(curl -fsS --max-time 30 "https://api.fxtwitter.com/2/status/$id")
if [[ $(jq -r '.code // empty' <<<"$response") != 200 ]]; then
  jq -r '"FxTwitter error: \(.code // "unknown") \(.message // "Post unavailable")"' <<<"$response" >&2
  exit 1
fi
if [[ $raw == true ]]; then
  printf '%s\n' "$response"
  exit 0
fi
jq -r '
  .status as $post |
  if $post == null or $post.type == "tombstone" then
    error("Post unavailable")
  else
    "URL: \($post.url // "unknown")",
    "Author: \($post.author.name // "unknown") (@\($post.author.screen_name // "unknown"))",
    "Date: \($post.created_at // "unknown")",
    "Text:\n\($post.text // "")",
    (if (($post.media.all // []) | length) > 0 then
      "Media:",
      ($post.media.all[] | "  \(.type // "media"): \(.url // .thumbnail_url // "unavailable")" + (if .altText? then " (alt: \(.altText))" else "" end))
    else empty end),
    (if $post.quote? then
      if $post.quote.type == "tombstone" then
        "Quote: unavailable (\($post.quote.reason // "unknown"))"
      else
        "Quote: \($post.quote.url // "unknown")\n\($post.quote.text // "")"
      end
    else empty end),
    (if $post.replying_to? then "Reply to: \($post.replying_to.url // "https://x.com/\($post.replying_to.screen_name)/status/\($post.replying_to.status)")" else empty end)
  end
' <<<"$response"
