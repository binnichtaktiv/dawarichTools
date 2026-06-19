# dawarichTools

Collection of bash scripts for managing Dawarich, a self-hosted location tracking application.

## Requirements

- Running Dawarich Docker setup
- PostgreSQL container named `dawarich_db`
- Bash shell

## Scripts

**dawarichPointInsert.sh** - Manually add GPS points to the Dawarich database. Supports single point entry and bulk imports with customizable dates and times. Coordinates can be copied directly from Google Maps.

**dawarichCopyPoints.sh** - Copy existing GPS points from the database. Useful for backing up or transferring location data.

**dawarichDB.sh** - Database management helper script for accessing the Dawarich PostgreSQL container.

**dawarichRails.sh** - Rails console access script for direct interaction with the Dawarich application.

## Configuration

Timezone is set to Europe/Berlin by default and can be adjusted in the scripts as needed.
