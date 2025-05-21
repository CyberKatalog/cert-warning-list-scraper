#!/bin/bash

# Script to analyze CERT.PL domain actions files
# This script generates summary statistics based on the downloaded files

# Configuration
DATA_DIR="$(dirname "$0")/data"
METADATA_FILE="$(dirname "$0")/metadata.json"
REPORT_DIR="$(dirname "$0")/reports"
SUMMARY_FILE="${REPORT_DIR}/summary.txt"

# Create report directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
  echo "Error: Data directory not found at $DATA_DIR"
  exit 1
fi

# Check if metadata file exists
if [ ! -f "$METADATA_FILE" ]; then
  echo "Error: Metadata file not found at $METADATA_FILE"
  exit 1
fi

# Generate summary report
echo "CERT.PL Domain Actions Summary Report" >"$SUMMARY_FILE"
echo "Generated on: $(date)" >>"$SUMMARY_FILE"
echo "------------------------------------------" >>"$SUMMARY_FILE"
echo "" >>"$SUMMARY_FILE"

# Report on data files
echo "Files available:" >>"$SUMMARY_FILE"
echo "" >>"$SUMMARY_FILE"

printf "%-20s %-15s %-15s %-25s %-25s\n" "Filename" "Size" "Downloads" "Last Success" "Last Check" >>"$SUMMARY_FILE"
printf "%-20s %-15s %-15s %-25s %-25s\n" "--------" "----" "---------" "------------" "----------" >>"$SUMMARY_FILE"

# Loop through metadata entries
jq -r 'to_entries | .[] | [.key, .value.size, .value.download_count, .value.lastSuccess, .value.last_check] | @tsv' "$METADATA_FILE" |
  while IFS=$'\t' read -r filename size downloads lastSuccess lastCheck; do
    printf "%-20s %-15s %-15s %-25s %-25s\n" "$filename" "$size" "$downloads" "$lastSuccess" "$lastCheck" >>"$SUMMARY_FILE"
  done

echo "" >>"$SUMMARY_FILE"
echo "Total size of all files: $(du -h -c $DATA_DIR/*.log 2>/dev/null | grep total | cut -f 1) ($(find $DATA_DIR -name "*.log" | wc -l) files)" >>"$SUMMARY_FILE"
echo "" >>"$SUMMARY_FILE"

# Check for any download failures
echo "Recent download failures:" >>"$SUMMARY_FILE"
failures=$(jq -r 'to_entries[] | select(.value.lastSuccess != .value.last_check) | .key' "$METADATA_FILE")
if [ -z "$failures" ]; then
  echo "No recent failures detected." >>"$SUMMARY_FILE"
else
  echo "$failures" >>"$SUMMARY_FILE"
fi

echo "" >>"$SUMMARY_FILE"
echo "Download statistics from metadata:" >>"$SUMMARY_FILE"
echo "------------------------------------------" >>"$SUMMARY_FILE"
jq -r 'to_entries | sort_by(.key) | .[] | "File: \(.key)\n  URL: \(.value.url)\n  Size: \(.value.size) bytes\n  Checksum: \(.value.checksum)\n  Download time: \(.value.download_time_seconds) seconds\n  Last successful download: \(.value.lastSuccess)\n  Last check: \(.value.last_check)\n  Download count: \(.value.download_count)\n"' "$METADATA_FILE" >>"$SUMMARY_FILE"

echo "Summary report generated at $SUMMARY_FILE"
