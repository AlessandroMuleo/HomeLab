# Incidents

Things that went wrong and what changed because of them.

## Blackout, external HDD dead

A power cut took down the pi and the external HDD with the Nextcloud data.
When power came back the disk didn't come up anymore, and I wasn't taking
backups of the data yet.

What changed:

- UPS (APC Back-UPS 700) with NUT, the pi shuts down cleanly on low battery
  and HA sends a notification when it goes on battery
- second disk, nightly snapshots with `scripts/backup.sh`
- `nofail` + short timeout in fstab for both disks, so a dead disk doesn't
  block the boot
- docker waits for `/mnt/hdd` (`system/docker-wait-for-hdd.conf`), so nextcloud
  doesn't start against an empty mountpoint
- `scripts/check-disk.sh` every morning, SMART + free space

Still missing: an offsite copy. Both disks sit next to each other on the same
shelf, a fire or a theft takes both. Probably restic to some cheap storage,
encrypted.

## Home Assistant and Nextcloud open to the internet

Not an incident strictly speaking, nothing happened (as far as I know), but they
were port-forwarded on the Fritz!Box for a long time. Closed, only WireGuard
is forwarded now. See [network.md](network.md#port-forwarding).
