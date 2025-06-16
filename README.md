# CERT.PL Warning List Scraper

This project automatically downloads and maintains an archive of CERT.PL domain action logs from their public repository.

## Features

- Automatically downloads CERT.PL domain action logs from 2020 to the current year
- Validates files using SHA-256 checksums to avoid unnecessary updates
- Maintains detailed metadata about each file (size, checksum, download times, etc.)
- Generates summary reports of the downloaded data
- Configures cron jobs for automatic updates

## Setup

1. Make the scripts executable:

   ```
   chmod +x *.sh
   ```

2. Run the setup script to configure the cron job:

   ```
   ./setup_cron.sh
   ```

3. Perform an initial download:

   ```
   ./download_cert_files.sh
   ```

4. Generate a summary report:
   ```
   ./analyze_cert_data.sh
   ```

## Directory Structure

- `data/` - Contains the downloaded log files
- `reports/` - Contains generated reports
- `download_cert_files.sh` - Main script for downloading files
- `analyze_cert_data.sh` - Script for analyzing the downloaded data
- `setup_cron.sh` - Script for setting up cron jobs
- `metadata.json` - File containing metadata about each downloaded file

## Sample Outputs

Sample outputs from this tool can be found at: https://github.com/silesiansolutions/cert-warning-list-scraper/tree/sample_output

## Metadata Format

The metadata.json file maintains information about each downloaded file in the following format:

```json
{
  "actions_YYYY.log": {
    "url": "https://hole.cert.pl/domains/v2/actions_YYYY.log",
    "size": "1234567",
    "checksum": "sha256hash",
    "download_time_seconds": "12",
    "lastSuccess": "YYYY-MM-DD HH:MM:SS",
    "last_check": "YYYY-MM-DD HH:MM:SS",
    "download_count": "1"
  },
  ...
}
```

## Cron Job Configuration

By default, the download script runs daily at 3:00 AM and the analyze script runs at 3:30 AM. You can modify this schedule by editing your crontab:

```
crontab -e
```

## Requirements

- Bash shell
- curl
- jq (for JSON processing)
- shasum (for checksum calculation)

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

## Author

This project was created for [Cyber Katalog](https://cyberkatalog.pl) and developed by [Silesian Solutions](https://silesiansolutions.com).
