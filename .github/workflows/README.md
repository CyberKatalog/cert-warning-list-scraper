# GitHub Actions Workflow for CERT.PL Data Collection

This workflow automates the process of downloading CERT.PL domain action logs and making them available as artifacts.

## Workflow Overview

- **Name**: Download CERT.PL Files
- **Schedule**: Daily at 3:00 UTC
- **Manual Trigger**: Available through the GitHub UI (workflow_dispatch)

## Job Steps

1. **Checkout Repository**: Checks out the code from the repository
2. **Install Dependencies**: Installs curl and jq on the Ubuntu runner
3. **Make Script Executable**: Makes the download script executable
4. **Run Download Script**: Executes the download_cert_files.sh script
5. **Check Downloaded Data**: Lists the downloaded files and displays metadata
6. **Archive Data Files**: Creates an artifact from the data folder
7. **Create ZIP Archive**: Packages the data folder into a ZIP file with date stamp
8. **Upload ZIP as Artifact**: Makes the ZIP file available as a separate artifact

## Artifacts

The workflow produces two artifacts:

1. **cert-pl-data**: The raw data folder containing all downloaded files
2. **cert-pl-data-zip**: A ZIP archive of the data folder with timestamp

Both artifacts are retained for 30 days.

## Environment

The workflow runs on the latest Ubuntu environment available in GitHub Actions.

## Customization

To modify the workflow, edit the `.github/workflows/download-cert-files.yml` file:

- Change the schedule by modifying the cron expression
- Adjust retention days for artifacts
- Add notification steps (email, Slack, etc.)
- Include additional processing steps for the downloaded data
