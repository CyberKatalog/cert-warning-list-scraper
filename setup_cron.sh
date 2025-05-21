#!/bin/bash

# Script to set up cron job for CERT.PL file downloads
# This script helps configure the automated download of CERT.PL domain action logs

# Get the absolute path of the script directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
DOWNLOAD_SCRIPT="${SCRIPT_DIR}/download_cert_files.sh"
ANALYZE_SCRIPT="${SCRIPT_DIR}/analyze_cert_data.sh"
LOG_FILE="${SCRIPT_DIR}/cron_download.log"

# Make sure scripts are executable
chmod +x "$DOWNLOAD_SCRIPT"
chmod +x "$ANALYZE_SCRIPT"

# Display current cron jobs
echo "Current cron jobs for $(whoami):"
crontab -l

# Create a temporary file for the new crontab
crontab -l >/tmp/current_crontab 2>/dev/null || echo "" >/tmp/current_crontab

# Check if our job is already in the crontab
if grep -q "$DOWNLOAD_SCRIPT" /tmp/current_crontab; then
  echo "Cron job for CERT.PL downloads already exists."
  echo "Current configuration:"
  grep "$DOWNLOAD_SCRIPT" /tmp/current_crontab
else
  # Suggest a default schedule (daily at 3:00 AM)
  echo "No existing cron job found for CERT.PL downloads."
  echo "Adding a new cron job to run daily at 3:00 AM."

  # Add the new cron job
  echo "# CERT.PL domain list download - runs daily at 3:00 AM" >>/tmp/current_crontab
  echo "0 3 * * * $DOWNLOAD_SCRIPT >> $LOG_FILE 2>&1" >>/tmp/current_crontab
  echo "30 3 * * * $ANALYZE_SCRIPT >> $LOG_FILE 2>&1" >>/tmp/current_crontab

  # Install the new crontab
  crontab /tmp/current_crontab
  echo "Cron job has been added successfully."
fi

# Clean up
rm /tmp/current_crontab

# Create directory structure
mkdir -p "${SCRIPT_DIR}/data"
mkdir -p "${SCRIPT_DIR}/reports"

# Initial run suggestion
echo ""
echo "Directory structure has been prepared."
echo "You can manually run the download script now with:"
echo "  $DOWNLOAD_SCRIPT"
echo ""
echo "And then analyze the data with:"
echo "  $ANALYZE_SCRIPT"
echo ""
echo "The scripts will automatically run according to the cron schedule."
echo "Logs will be saved to: $LOG_FILE"
