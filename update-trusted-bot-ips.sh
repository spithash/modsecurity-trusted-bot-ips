#!/bin/bash

# Script: update-trusted-bot-ips.sh
# What it does: grabs trusted bot IP ranges from Google and Bing JSON files
# and saves them to a flat file you can use in ModSecurity or your firewall.
# Repo: https://github.com/spithash/modsecurity-trusted-bot-ips
# Author: Stathis Xantinidis

# URLs where we fetch the JSON with IP ranges
URLS=(
  "https://www.gstatic.com/ipranges/goog.json"                        # Google Cloud & services
  "https://www.bing.com/toolbox/bingbot.json"                         # Bingbot IPs
  "https://developers.google.com/search/apis/ipranges/googlebot.json" # Googlebot IPs
)

# Where to save the combined IP list
OUTPUT_FILE="/etc/modsecurity/google_bing_googlebot_ips.txt"

# Make sure the folder for the output file exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Start fresh by emptying the output file
: >"$OUTPUT_FILE"

# Counters to keep track of how many IPs we find
TOTAL_IPV4=0
TOTAL_IPV6=0

# Go through each URL and grab the IP ranges
for URL in "${URLS[@]}"; do
  echo "--------------------------------------------------"
  echo "Downloading from: $URL"

  # Create a temp file for the JSON download
  TMP_JSON=$(mktemp)
  if [ -z "$TMP_JSON" ]; then
    echo "❌ Uh oh, couldn't make a temp file. Exiting."
    exit 1
  fi

  # Download the JSON quietly, but fail if HTTP errors happen
  if ! curl -f -sSL -o "$TMP_JSON" "$URL"; then
    echo "❌ Failed to get JSON from $URL"
    rm -f "$TMP_JSON"
    continue
  fi

  # Make sure the file actually has something in it
  if [ ! -s "$TMP_JSON" ]; then
    echo "❌ Downloaded JSON from $URL is empty, skipping."
    rm -f "$TMP_JSON"
    continue
  fi

  # Check if the JSON has the 'prefixes' array with data
  if jq -e '.prefixes | type == "array" and length > 0' "$TMP_JSON" >/dev/null; then
    # Count how many IPv4 and IPv6 prefixes we got
    COUNT_IPV4=$(jq '[.prefixes[] | select(.ipv4Prefix)] | length' "$TMP_JSON")
    COUNT_IPV6=$(jq '[.prefixes[] | select(.ipv6Prefix)] | length' "$TMP_JSON")

    echo "Found $COUNT_IPV4 IPv4 and $COUNT_IPV6 IPv6 IPs."

    # Add the IPs to our output file
    jq -r '.prefixes[] | select(.ipv4Prefix) | .ipv4Prefix' "$TMP_JSON" >>"$OUTPUT_FILE"
    jq -r '.prefixes[] | select(.ipv6Prefix) | .ipv6Prefix' "$TMP_JSON" >>"$OUTPUT_FILE"

    # Keep a running total
    TOTAL_IPV4=$((TOTAL_IPV4 + COUNT_IPV4))
    TOTAL_IPV6=$((TOTAL_IPV6 + COUNT_IPV6))

    echo "✓ Added IPs from $URL"
  else
    echo "⚠️ No IP prefixes found in the JSON from $URL"
  fi

  # Clean up the temp file
  rm -f "$TMP_JSON"
done

# Remove duplicates just in case
sort -u -o "$OUTPUT_FILE" "$OUTPUT_FILE"

# Show a summary of what we got
TOTAL_ALL=$((TOTAL_IPV4 + TOTAL_IPV6))
echo "--------------------------------------------------"
echo "✅ IPv4 addresses found: $TOTAL_IPV4"
echo "✅ IPv6 addresses found: $TOTAL_IPV6"
echo "📦 Total IPs saved: $TOTAL_ALL"
echo "📄 Saved to: $OUTPUT_FILE"
