#!/usr/bin/env bash
set -euo pipefail

DB_CONTAINER="dawarich_db"
DB_USER="postgres"
DB_NAME="dawarich_development"
USER_ID="1"
TIMEZONE="Europe/Berlin"

docker start "$DB_CONTAINER" >/dev/null 2>&1 || true
until docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; do sleep 1; done

read -rp "Straße: " STREET

docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" \
  -v street="$STREET" -v uid="$USER_ID" -v tz="$TIMEZONE" <<'SQL'
SELECT
    DATE(to_timestamp(timestamp) AT TIME ZONE :'tz') AS visit_date,
    MIN(to_timestamp(timestamp) AT TIME ZONE :'tz')  AS first_tracked_point,
    MAX(to_timestamp(timestamp) AT TIME ZONE :'tz')  AS last_tracked_point,
    COUNT(*)                                          AS points_count
FROM points
WHERE user_id = :uid
  AND geodata -> 'properties' ->> 'street' ILIKE '%' || :'street' || '%'
GROUP BY 1
ORDER BY 1 DESC;
SQL
