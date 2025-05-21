#!/bin/bash

# Script to download CERT.PL domain actions files
# This script downloads yearly CERT.PL domain action logs and maintains metadata about each file

# Configuration
DOWNLOAD_DIR="$(dirname "$0")/data"
METADATA_FILE="$(dirname "$0")/metadata.json"
CURRENT_YEAR=$(date +%Y)
BASE_URL="https://hole.cert.pl/domains/v2"
START_YEAR=2020

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Initialize metadata file if it doesn't exist
if [ ! -f "$METADATA_FILE" ]; then
  echo "{}" >"$METADATA_FILE"
fi

# Function to calculate checksum
calculate_checksum() {
  shasum -a 256 "$1" | cut -d ' ' -f 1
}

# Function to update metadata for a file
update_metadata() {
  local file="$1"
  local url="$2"
  local filesize
  # Check system type for stat compatibility
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    filesize=$(stat -f %z "$file")
  else
    # Linux and other systems
    filesize=$(stat -c %s "$file")
  fi
  local checksum=$(calculate_checksum "$file")
  local download_time="$3"
  local success="$4"
  local basename=$(basename "$file")

  # Get current timestamp
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  # Check if entry exists
  if jq -e ".\"$basename\"" "$METADATA_FILE" >/dev/null 2>&1; then
    # Update existing entry
    if [ "$success" = "true" ]; then
      jq --arg basename "$basename" \
        --arg url "$url" \
        --arg size "$filesize" \
        --arg checksum "$checksum" \
        --arg download_time "$download_time" \
        --arg timestamp "$timestamp" \
        '.[$basename].url = $url | 
          .[$basename].size = $size | 
          .[$basename].checksum = $checksum | 
          .[$basename].download_time_seconds = $download_time | 
          .[$basename].lastSuccess = $timestamp | 
          .[$basename].last_check = $timestamp' "$METADATA_FILE" >temp.json && mv temp.json "$METADATA_FILE"
    else
      jq --arg basename "$basename" \
        --arg timestamp "$timestamp" \
        '.[$basename].last_check = $timestamp' "$METADATA_FILE" >temp.json && mv temp.json "$METADATA_FILE"
    fi
  else
    # Create new entry
    jq --arg basename "$basename" \
      --arg url "$url" \
      --arg size "$filesize" \
      --arg checksum "$checksum" \
      --arg download_time "$download_time" \
      --arg timestamp "$timestamp" \
      '.[$basename] = {
         "url": $url,
         "size": $size,
         "checksum": $checksum,
         "download_time_seconds": $download_time,
         "lastSuccess": $timestamp,
         "last_check": $timestamp,
         "download_count": 1
       }' "$METADATA_FILE" >temp.json && mv temp.json "$METADATA_FILE"
  fi
}

# Function to increment download count
increment_download_count() {
  local basename="$1"

  jq --arg basename "$basename" \
    '.[$basename].download_count = ((.[$basename].download_count | tonumber) + 1) | .[$basename].download_count |= tostring' \
    "$METADATA_FILE" >temp.json && mv temp.json "$METADATA_FILE"
}

# Download files for each year from START_YEAR to current year
for year in $(seq $START_YEAR $CURRENT_YEAR); do
  filename="actions_${year}.log"
  url="${BASE_URL}/${filename}"
  output_file="${DOWNLOAD_DIR}/${filename}"
  temp_file="${DOWNLOAD_DIR}/.${filename}.tmp"

  echo "[$(date +"%Y-%m-%d %H:%M:%S")] Processing $filename..."

  # Get start time
  start_time=$(date +%s)

  # Download the file to a temporary location
  if curl -s -f -o "$temp_file" "$url"; then
    # Calculate time taken
    end_time=$(date +%s)
    download_time=$((end_time - start_time))

    # Check if the file already exists
    if [ -f "$output_file" ]; then
      existing_checksum=$(calculate_checksum "$output_file")
      new_checksum=$(calculate_checksum "$temp_file")

      if [ "$existing_checksum" != "$new_checksum" ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Checksum changed for $filename, updating file"
        mv "$temp_file" "$output_file"
        update_metadata "$output_file" "$url" "$download_time" "true"
        increment_download_count "$filename"
      else
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] No changes detected for $filename"
        rm "$temp_file"
        # Update last_check in metadata
        update_metadata "$output_file" "$url" "$download_time" "true"
      fi
    else
      echo "[$(date +"%Y-%m-%d %H:%M:%S")] Downloaded new file: $filename"
      mv "$temp_file" "$output_file"
      update_metadata "$output_file" "$url" "$download_time" "true"
    fi
  else
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Failed to download $filename"
    # Update metadata to indicate a failed attempt
    if [ -f "$output_file" ]; then
      end_time=$(date +%s)
      download_time=$((end_time - start_time))
      update_metadata "$output_file" "$url" "$download_time" "false"
    fi
    # Clean up temp file if it exists
    [ -f "$temp_file" ] && rm "$temp_file"
  fi
done

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Download process completed"
