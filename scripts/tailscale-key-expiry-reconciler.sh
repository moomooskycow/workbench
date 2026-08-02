#!/bin/bash

set -euo pipefail

MINT_PROXY_BASE_URL='http://mint.tail5f5eb4.ts.net:4949/proxy/https/api.tailscale.com/api/v2'
TAILNET='tail5f5eb4.ts.net'
AUTHORIZATION_HEADER='Authorization: Bearer __mint.tailscale.default__'

for required_command in curl jq mktemp; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'ERROR: required command is unavailable: %s\n' "$required_command" >&2
    exit 1
  fi
done

umask 077
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/workbench-tailscale.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

device_response="$temp_dir/devices.json"
node_ids="$temp_dir/node-ids"
update_response="$temp_dir/update.json"

device_list_url="$MINT_PROXY_BASE_URL/tailnet/$TAILNET/devices"

if ! curl \
  --max-time 30 \
  --proto '=http' \
  --noproxy '*' \
  --silent \
  --show-error \
  --fail \
  --request GET \
  --header "$AUTHORIZATION_HEADER" \
  "$device_list_url" >"$device_response"; then
  printf 'ERROR: Tailscale device list request failed\n' >&2
  exit 1
fi

if ! jq -e '
  if type != "object" or (.devices | type) != "array" then
    false
  else
    all(.devices[];
      type == "object"
      and (.nodeId | type) == "string"
      and (.nodeId | test("^n[A-Za-z0-9]+CNTRL$"))
    )
  end
' "$device_response" >/dev/null 2>&1; then
  printf 'ERROR: Tailscale device list response was not valid\n' >&2
  exit 1
fi

if ! jq -r '.devices[] | select(.keyExpiryDisabled != true and .isExternal != true) | .nodeId' \
  "$device_response" >"$node_ids"; then
  printf 'ERROR: Tailscale device list could not be reconciled\n' >&2
  exit 1
fi

updated_count=0
failure_count=0
while IFS= read -r node_id; do
  if [ -z "$node_id" ]; then
    printf 'ERROR: Tailscale device list contained an empty node ID\n' >&2
    exit 1
  fi

  if ! curl \
    --max-time 30 \
    --proto '=http' \
    --noproxy '*' \
    --silent \
    --show-error \
    --fail \
    --request POST \
    --header "$AUTHORIZATION_HEADER" \
    --header 'Content-Type: application/json' \
    --data-binary '{"keyExpiryDisabled":true}' \
    "$MINT_PROXY_BASE_URL/device/$node_id/key" >"$update_response"; then
    printf 'ERROR: Tailscale key expiry update failed for node %s\n' "$node_id" >&2
    failure_count=$((failure_count + 1))
    continue
  fi

  if ! jq -e 'type == "object"' "$update_response" >/dev/null 2>&1; then
    printf 'ERROR: Tailscale key expiry update returned invalid JSON for node %s\n' "$node_id" >&2
    failure_count=$((failure_count + 1))
    continue
  fi

  updated_count=$((updated_count + 1))
done < "$node_ids"

if [ "$updated_count" -eq 0 ]; then
  printf 'Tailscale key expiry reconciliation: no drift found\n'
else
  printf 'Tailscale key expiry reconciliation: updated %s device(s)\n' "$updated_count"
fi

if [ "$failure_count" -ne 0 ]; then
  printf 'ERROR: Tailscale key expiry reconciliation failed for %s device(s)\n' \
    "$failure_count" >&2
  exit 1
fi
