#!/bin/bash

PSQL="docker exec -i dawarich_db psql -U postgres -d dawarich_development"

# Convert DD-MM-YYYY HH:MM:SS → YYYY-MM-DD HH:MM:SS
to_iso() {
    echo "${1:6:4}-${1:3:2}-${1:0:2} ${1:11}"
}

echo "Source start  (DD-MM-YYYY HH:MM:SS Berlin): "; read SRC_START
echo "Source end    (DD-MM-YYYY HH:MM:SS Berlin): "; read SRC_END
echo "Target start  (DD-MM-YYYY HH:MM:SS Berlin): "; read TGT_START

REGEX='^[0-9]{2}-[0-9]{2}-[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
for V in "$SRC_START" "$SRC_END" "$TGT_START"; do
    [[ ! "$V" =~ $REGEX ]] && echo "Invalid format: $V" && exit 1
done

S=$(to_iso "$SRC_START")
E=$(to_iso "$SRC_END")
T=$(to_iso "$TGT_START")

OFFSET="('$T'::timestamp AT TIME ZONE 'Europe/Berlin') - ('$S'::timestamp AT TIME ZONE 'Europe/Berlin')"
WHERE="\"timestamp\" BETWEEN EXTRACT(EPOCH FROM ('$S'::timestamp AT TIME ZONE 'Europe/Berlin'))::bigint AND EXTRACT(EPOCH FROM ('$E'::timestamp AT TIME ZONE 'Europe/Berlin'))::bigint"

echo ""
echo "== Preview =="
$PSQL << SQL
SELECT
    id,
    to_timestamp("timestamp") AT TIME ZONE 'Europe/Berlin' AS original,
    to_timestamp("timestamp" + EXTRACT(EPOCH FROM ($OFFSET))::bigint) AT TIME ZONE 'Europe/Berlin' AS new_time,
    latitude,
    longitude
FROM points
WHERE $WHERE
ORDER BY "timestamp";
SQL

COUNT=$($PSQL -t -A -c "SELECT COUNT(*) FROM points WHERE $WHERE;" 2>/dev/null | tr -d ' ')
echo ""
echo "$COUNT points found."
[[ "$COUNT" -eq 0 ]] && echo "Nothing to copy." && exit 1

echo ""
read -p "Copy? [y/N]: " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && echo "Aborted." && exit 0

echo ""
echo "== Insert =="
$PSQL -v ON_ERROR_STOP=1 << SQL
BEGIN;
INSERT INTO points (
    battery_status, ping, battery, tracker_id, topic,
    altitude, longitude, velocity, "trigger", bssid, ssid, connection,
    vertical_accuracy, accuracy, "timestamp", latitude, mode,
    inrids, in_regions, raw_data, import_id, city, country,
    created_at, updated_at, user_id, geodata,
    visit_id, reverse_geocoded_at, course, course_accuracy,
    external_track_id, lonlat, country_id, track_id, country_name,
    raw_data_archived, motion_data, altitude_decimal, anomaly
)
SELECT
    battery_status, ping, battery, tracker_id, topic,
    altitude, longitude, velocity, "trigger", bssid, ssid, connection,
    vertical_accuracy, accuracy,
    "timestamp" + EXTRACT(EPOCH FROM ($OFFSET))::bigint,
    latitude, mode,
    inrids, in_regions, raw_data, import_id, city, country,
    NOW(), NOW(), user_id, geodata,
    NULL, NULL, course, course_accuracy,
    NULL, lonlat, country_id, NULL, country_name,
    false, motion_data, altitude_decimal, anomaly
FROM points
WHERE $WHERE
ON CONFLICT DO NOTHING;
COMMIT;
SQL

[[ $? -ne 0 ]] && echo "ERROR: transaction failed, rolled back." && exit 1
echo "Done."
