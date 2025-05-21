#!/bin/bash

# Script to manually trigger and manage GitHub Actions workflow artifacts
# For CERT.PL domain actions files

# Configuration
REPO_OWNER="YOUR_GITHUB_USERNAME"  # Replace with your GitHub username
REPO_NAME="cert-warning-list-scraper"  # Replace with your repository name
WORKFLOW_ID="download-cert-files.yml"
GITHUB_TOKEN=""  # Your GitHub Personal Access Token (can be set via environment variable)
ARTIFACT_DIR="$(dirname "$0")/artifacts"

# Check for GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
  if [ -n "$GITHUB_API_TOKEN" ]; then
    GITHUB_TOKEN="$GITHUB_API_TOKEN"
  else
    echo "Error: GitHub token not found. Please set GITHUB_TOKEN environment variable."
    echo "You can create a token at https://github.com/settings/tokens"
    exit 1
  fi
fi

# Create artifacts directory
mkdir -p "$ARTIFACT_DIR"

# Display menu
echo "CERT.PL Data Workflow Manager"
echo "----------------------------"
echo "1. Trigger workflow run"
echo "2. List recent workflow runs"
echo "3. Download latest artifacts"
echo "4. Exit"
echo ""

read -p "Select an option (1-4): " option

case $option in
  1)
    # Trigger workflow
    echo "Triggering GitHub Actions workflow..."
    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/$WORKFLOW_ID/dispatches" \
      -d '{"ref":"main"}'
    
    if [ $? -eq 0 ]; then
      echo "Workflow triggered successfully. Check GitHub Actions tab for progress."
    else
      echo "Error triggering workflow."
    fi
    ;;
    
  2)
    # List recent workflow runs
    echo "Fetching recent workflow runs..."
    curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/$WORKFLOW_ID/runs" | \
      jq -r '.workflow_runs[] | "ID: \(.id) | Status: \(.status) | Conclusion: \(.conclusion) | Created: \(.created_at) | URL: \(.html_url)"' | \
      head -10
    ;;
    
  3)
    # Download latest artifacts
    echo "Fetching latest workflow runs..."
    LATEST_RUN_ID=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/$WORKFLOW_ID/runs" | \
      jq -r '.workflow_runs[0].id')
    
    if [ -z "$LATEST_RUN_ID" ] || [ "$LATEST_RUN_ID" == "null" ]; then
      echo "No workflow runs found."
      exit 1
    fi
    
    echo "Fetching artifacts for run ID: $LATEST_RUN_ID"
    ARTIFACTS=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$LATEST_RUN_ID/artifacts")
    
    ARTIFACT_COUNT=$(echo "$ARTIFACTS" | jq '.total_count')
    
    if [ "$ARTIFACT_COUNT" -eq 0 ]; then
      echo "No artifacts found for this workflow run."
      exit 1
    fi
    
    echo "Found $ARTIFACT_COUNT artifacts. Downloading..."
    
    echo "$ARTIFACTS" | jq -r '.artifacts[] | "\(.id) \(.name) \(.archive_download_url)"' | \
    while read -r ID NAME URL; do
      echo "Downloading $NAME..."
      curl -s -L \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$URL" > "$ARTIFACT_DIR/$NAME.zip"
      
      echo "Downloaded to $ARTIFACT_DIR/$NAME.zip"
    done
    
    echo "All artifacts downloaded to $ARTIFACT_DIR"
    ;;
    
  4)
    echo "Exiting."
    exit 0
    ;;
    
  *)
    echo "Invalid option selected."
    exit 1
    ;;
esac
