# Restore

Snapshots are in `/mnt/backup/snapshots/YYYY-MM-DD/`, `latest` points to the
newest one. Every snapshot is a full tree (hardlinks), so any of them can be
used directly, no chain to replay.

```
2026-01-01/
  nextcloud.sql
  nextcloud-data/
  nextcloud-config/
  homeassistant/
  pihole/
  wireguard/
  nut/
```

## Single file from Nextcloud

Just copy it back into the user's files dir and rescan:

```sh
S=/mnt/backup/snapshots/latest
sudo cp -a "$S/nextcloud-data/<user>/files/path/to/file" /mnt/hdd/nextcloud/<user>/files/path/to/
docker exec -u www-data nextcloud php occ files:scan --path="<user>/files/path/to"
```

## Whole Nextcloud (e.g. new data disk)

Containers must already exist (setup.md step 4), with the same passwords in `.env`.

```sh
source /opt/homelab/.env
S=/mnt/backup/snapshots/latest

docker exec -u www-data nextcloud php occ maintenance:mode --on

sudo rsync -a --delete "$S/nextcloud-data/"   /mnt/hdd/nextcloud/
sudo rsync -a --delete "$S/nextcloud-config/" /srv/nextcloud/html/config/

docker exec -i nextcloud-db mariadb -u root -p"$MYSQL_ROOT_PASSWORD" \
    -e "DROP DATABASE nextcloud; CREATE DATABASE nextcloud;"
docker exec -i nextcloud-db mariadb -u root -p"$MYSQL_ROOT_PASSWORD" nextcloud < "$S/nextcloud.sql"

docker exec -u www-data nextcloud php occ maintenance:mode --off
docker exec -u www-data nextcloud php occ maintenance:data-fingerprint
```

`data-fingerprint` tells the desktop/phone clients that the server went back in
time, otherwise they may think files were deleted and sync that.

For the sections below `S` is the snapshot to restore from, as above.

## Home Assistant

History (the sqlite db) is not in the backup on purpose. Everything else is:

```sh
docker compose stop homeassistant
sudo rsync -a "$S/homeassistant/" /opt/homelab/homeassistant/
docker compose start homeassistant
```

## Pi-hole, WireGuard, NUT

```sh
sudo rsync -a "$S/pihole/"    /srv/pihole/
sudo rsync -a "$S/wireguard/" /etc/wireguard/
sudo rsync -a "$S/nut/"       /etc/nut/
docker compose restart pihole
sudo systemctl restart wg-quick@wg0 nut-server nut-monitor
```

Restoring wireguard keeps the same server key, so no client needs to be touched.

## Testing

A backup that was never restored is not a backup. Every now and then: start a
throwaway compose project on the laptop, load `nextcloud.sql` and a copy of
`nextcloud-config/`, and check it comes up.
