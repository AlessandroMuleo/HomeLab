#!/usr/bin/env bash
# Nightly snapshot to the backup disk.
# rsync --link-dest hardlinks unchanged files against the previous snapshot,
# so every day is a full copy but only changed files take space.
# Runs as root from cron (needs /etc/wireguard and the docker socket).
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck source=/dev/null
source .env

DEST=${BACKUP_DEST:-/mnt/backup/snapshots}
KEEP=${BACKUP_KEEP:-14}
TODAY=$(date +%F)
SNAP="$DEST/$TODAY"

notify() {
    curl -fsS -m 10 -X POST -H 'Content-Type: application/json' \
        -d "{\"message\": \"$1\"}" "$HA_WEBHOOK_URL" >/dev/null || true
}

fail() {
    echo "backup failed: $1" >&2
    notify "backup failed: $1"
    exit 1
}

mountpoint -q "$(dirname "$DEST")" || fail "backup disk not mounted"
mountpoint -q /mnt/hdd || fail "data disk not mounted"

mkdir -p "$SNAP"

occ() {
    docker exec -u www-data nextcloud php occ "$@"
}

occ maintenance:mode --on
trap 'occ maintenance:mode --off' EXIT

docker exec nextcloud-db mariadb-dump --single-transaction \
    -u root -p"$MYSQL_ROOT_PASSWORD" nextcloud > "$SNAP/nextcloud.sql" \
    || fail "db dump"

snap() {
    local name=$1 src=$2
    shift 2
    local link=()
    if [ -d "$DEST/latest/$name" ] && [ "$(readlink "$DEST/latest")" != "$TODAY" ]; then
        link=(--link-dest="$DEST/latest/$name")
    fi
    rsync -a --delete "${link[@]}" "$@" "$src/" "$SNAP/$name/" || fail "rsync $name"
}

snap nextcloud-data   /mnt/hdd/nextcloud
snap nextcloud-config /srv/nextcloud/html/config
occ maintenance:mode --off
trap - EXIT

# the HA database is sqlite and gets written all the time, a copy of it
# is not reliable. history is not worth much anyway.
snap homeassistant ./homeassistant --exclude 'home-assistant_v2.db*' --exclude tts/
snap pihole        /srv/pihole --exclude 'pihole-FTL.db*'
snap wireguard     /etc/wireguard
snap nut           /etc/nut

ln -sfn "$TODAY" "$DEST/latest"

# keep the last $KEEP snapshots
find "$DEST" -mindepth 1 -maxdepth 1 -type d -name '20??-??-??' | sort | head -n -"$KEEP" \
    | xargs -r rm -rf

echo "backup ok: $SNAP"
