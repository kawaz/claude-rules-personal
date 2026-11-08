#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' \
    'Usage: x-search.sh "<question>" [--url <post-url>] [--since 24h|7d] [--unit stable|unstable] [--model <model>]' \
    '       x-search.sh --help' \
    '' \
    'Ask Grok to search recent X posts or examine media in a specified post.' \
    'Options:' \
    '  --url <post-url>       Include one X post and enable image/video understanding.' \
    '  --since <24h|7d>     Restrict topic searches (UTC; default: 24h; unused with --url).' \
    '  --unit <unit>        Gateway unit: stable (default) or unstable.' \
    '  --model <model>      Responses model (default: grok-4.7).' \
    '  --help               Show this help.'
}

if (( $# == 0 )); then usage; exit 0; fi
question=''
post_url=''
since=24h
unit=stable
model=grok-4.7
while (( $# > 0 )); do
  case "$1" in
    --help) usage; exit 0 ;;
    --url|--since|--unit|--model)
      option=$1
      if (( $# < 2 )) || [[ -z $2 ]]; then printf 'Missing value for %s.\n' "$option" >&2; exit 2; fi
      case "$option" in
        --url) post_url=$2 ;;
        --since) since=$2 ;;
        --unit) unit=$2 ;;
        --model) model=$2 ;;
      esac
      shift 2
      ;;
    --) shift; if (( $# != 1 )) || [[ -n $question ]]; then usage >&2; exit 2; fi; question=$1; shift ;;
    -*) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) if [[ -n $question ]]; then printf 'Specify exactly one question.\n' >&2; exit 2; fi; question=$1; shift ;;
  esac
done
if [[ -z $question ]]; then usage >&2; exit 2; fi
case "$since" in 24h|7d) ;; *) printf 'Expected --since 24h or 7d.\n' >&2; exit 2 ;; esac
case "$unit" in stable) port=11302 ;; unstable) port=11301 ;; *) printf 'Expected --unit stable or unstable.\n' >&2; exit 2 ;; esac
if [[ -n $post_url && ! $post_url =~ ^https://(www\.)?(x\.com|twitter\.com)/[^/?#]+/status/[0-9]{2,20}([/?#].*)?$ ]]; then
  printf 'Expected an https://x.com/<handle>/status/<id> post URL.\n' >&2
  exit 2
fi

if [[ -n $post_url ]]; then
  input=$(printf '%s\nTarget X post: %s\nExamine its images and videos, if present, rather than inferring their contents solely from its text. Include direct post links and distinguish post contents from your inference.' "$question" "$post_url")
  tool=$(jq -n '{type:"x_search",enable_image_understanding:true,enable_video_understanding:true}')
else
  # X Search filters use UTC calendar dates; the prompt supplies the exact rolling window.
  now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  if [[ $since == 24h ]]; then days=1; else days=7; fi
  if from_date=$(date -u -d "$days days ago" '+%Y-%m-%d' 2>/dev/null); then
    to_date=$(date -u -d 'tomorrow' '+%Y-%m-%d')
  else
    from_date=$(date -u -v-"${days}"d '+%Y-%m-%d')
    to_date=$(date -u -v+1d '+%Y-%m-%d')
  fi
  input=$(printf '%s\nSearch X posts from the last %s ending at %s (UTC). Include direct post links, distinguish post contents from your inference, and do not include older posts.' "$question" "$since" "$now")
  tool=$(jq -n --arg from "$from_date" --arg to "$to_date" '{type:"x_search",from_date:$from,to_date:$to}')
fi

request=$(jq -n --arg model "$model" --arg input "$input" --argjson tool "$tool" '{model:$model,input:$input,tools:[$tool],max_turns:2,store:false}')
config="$HOME/.config/llm-gateway/config-${port}-${unit}.toml"
token=$(llm-gateway auth token --config "$config" --ns personal --sub x-search)
response=$(curl -fsS --max-time 180 -H "Authorization: Bearer $token" -H 'Content-Type: application/json' --data-binary "$request" "http://127.0.0.1:${port}/ns-personal/api.x.ai/v1/responses")
unset token request

if [[ $(jq -r '.status // empty' <<<"$response") != completed ]]; then
  jq -r '"Grok response \(.status // "unknown"): \(.error.message // .incomplete_details.reason // "Check the response and try again.")"' <<<"$response" >&2
  exit 1
fi
jq -r '
  [.output[]? | select(.type == "message") | .content[]? | select(.type == "output_text")]
  | if length == 0 then error("No output text in Grok response") else .[] | .text end
' <<<"$response"
printf '\nCitations:\n'
jq -r '[.output[]? | select(.type == "message") | .content[]? | .annotations[]? | select(.type == "url_citation") | .url] | unique | if length == 0 then "  (none)" else .[] end' <<<"$response"
