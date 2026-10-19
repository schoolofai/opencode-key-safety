#!/usr/bin/env bash
# check-key.sh: is an old AI provider key really dead?
# Usage: OLD_KEY=... ./scripts/check-key.sh openai|anthropic|gemini
# Prints only the HTTP status code. Never prints the key.
#   401 (or 400/403 for Gemini) = refused: the key is dead.
#   200 = the key still works: revoke it now in the provider's dashboard.
set -euo pipefail
provider="${1:-}"
if [ -z "${OLD_KEY:-}" ]; then
  read -r -s -p "Paste the OLD key (input hidden): " OLD_KEY; echo
fi
case "$provider" in
  openai)    code=$(curl -s -o /dev/null -w '%{http_code}' https://api.openai.com/v1/models -H "Authorization: Bearer $OLD_KEY") ;;
  anthropic) code=$(curl -s -o /dev/null -w '%{http_code}' https://api.anthropic.com/v1/models -H "x-api-key: $OLD_KEY" -H 'anthropic-version: 2023-06-01') ;;
  gemini)    code=$(curl -s -o /dev/null -w '%{http_code}' https://generativelanguage.googleapis.com/v1beta/models -H "x-goog-api-key: $OLD_KEY") ;;
  *) echo "usage: OLD_KEY=... $0 openai|anthropic|gemini" >&2; exit 2 ;;
esac
unset OLD_KEY
echo "$code"
case "$code" in
  200) echo "STILL LIVE: revoke this key now." >&2; exit 1 ;;
  401|400|403) echo "refused: the key is dead." >&2 ;;
  *) echo "unexpected status, check the provider's status page and try again." >&2 ;;
esac
