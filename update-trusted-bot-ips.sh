#!/bin/bash

# Script: update-trusted-bot-ips.sh
# Purpose: Fetch and extract trusted bot IP ranges from JSON files published by Google and Bing.
# Output: A flat list of IPv4 and IPv6 addresses saved to a file, suitable for ModSecurity or firewall whitelisting.
# Repo https://github.com/spithash/modsecurity-trusted-bot-ips
# By Stathis Xantinidis

# Define the URLs that contain the JSON files with bot IP ranges
URLS=(
  "https://www.gstatic.com/ipranges/goog.json"                        # Google Cloud & services
  "https://www.bing.com/toolbox/bingbot.json"                         # Bingbot IPs
  "https://developers.google.com/search/apis/ipranges/googlebot.json" # Googlebot IPs
)

# Define the output file path for the consolidated IPs
OUTPUT_FILE="/etc/modsecurity/google_bing_googlebot_ips.txt"

# Ensure the output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Empty the output file to start fresh
: >"$OUTPUT_FILE"

# Initialize total counters
TOTAL_IPV4=0
TOTAL_IPV6=0

# Loop through each URL to process IP ranges
for URL in "${URLS[@]}"; do
  echo "--------------------------------------------------"
  echo "Fetching data from: $URL"

  # Create a temporary file to store the downloaded JSON
  TMP_JSON=$(mktemp)

  # Get HTTP response code
  HTTP_CODE=$(curl -sSL -w "%{http_code}" -o "$TMP_JSON" "$URL")

  echo "HTTP response code: $HTTP_CODE"

  # Validate download and check if file is not empty
  if [ "$HTTP_CODE" -ne 200 ] || [ ! -s "$TMP_JSON" ]; then
    echo "❌ Error: Failed to download or empty JSON response from $URL"
    rm "$TMP_JSON"
    continue
  fi

  # Check if the JSON contains 'prefixes' array
  if jq -e '.prefixes | type == "array" and length > 0' "$TMP_JSON" >/dev/null; then
    # Count IPv4 and IPv6 prefixes
    COUNT_IPV4=$(jq '[.prefixes[] | select(.ipv4Prefix)] | length' "$TMP_JSON")
    COUNT_IPV6=$(jq '[.prefixes[] | select(.ipv6Prefix)] | length' "$TMP_JSON")

    echo "Found $COUNT_IPV4 IPv4 and $COUNT_IPV6 IPv6 entries."

    # Append IPs to output file
    jq -r '.prefixes[] | select(.ipv4Prefix) | .ipv4Prefix' "$TMP_JSON" >>"$OUTPUT_FILE"
    jq -r '.prefixes[] | select(.ipv6Prefix) | .ipv6Prefix' "$TMP_JSON" >>"$OUTPUT_FILE"

    # Update total counters
    TOTAL_IPV4=$((TOTAL_IPV4 + COUNT_IPV4))
    TOTAL_IPV6=$((TOTAL_IPV6 + COUNT_IPV6))

    echo "✓ Extracted and saved IPs from $URL"
  else
    echo "⚠️ Warning: No valid IP prefixes found in JSON from $URL"
  fi

  # Clean up
  rm "$TMP_JSON"
done

# Deduplicate the output (optional but recommended)
sort -u -o "$OUTPUT_FILE" "$OUTPUT_FILE"

# Final summary
TOTAL_ALL=$((TOTAL_IPV4 + TOTAL_IPV6))
echo "--------------------------------------------------"
echo "✅ Total IPv4 addresses: $TOTAL_IPV4"
echo "✅ Total IPv6 addresses: $TOTAL_IPV6"
echo "📦 Combined total saved: $TOTAL_ALL"
echo "📄 Output file: $OUTPUT_FILE"
