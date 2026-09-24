#!/usr/bin/env bash
# SMART health + free space on the usb disks. Sends a notification through
# home assistant if something looks wrong. Nothing is printed when all is fine.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
# shellcheck source=/dev/null
source .env

MOUNTS=(/mnt/hdd /mnt/backup)
MAX_USED=90

problems=()

for m in "${MOUNTS[@]}"; do
    if ! mountpoint -q "$m"; then
        problems+=("$m not mounted")
        continue
    fi

    used=$(df --output=pcent "$m" | tail -1 | tr -dc '0-9')
    if [ "$used" -ge "$MAX_USED" ]; then
        problems+=("$m is ${used}% full")
    fi

    # partition -> disk (sda1 -> sda)
    part=$(findmnt -no SOURCE "$m")
    disk="/dev/$(lsblk -no PKNAME "$part")"

    # -d sat is needed behind the usb-sata adapters, otherwise smartctl
    # can't see the disk at all
    if ! smartctl -H -d sat "$disk" >/dev/null; then
        problems+=("SMART check failed on $disk ($m)")
    fi

    realloc=$(smartctl -A -d sat "$disk" | awk '$2 == "Reallocated_Sector_Ct" {print $10}')
    if [ -n "$realloc" ] && [ "$realloc" -gt 0 ]; then
        problems+=("$disk has $realloc reallocated sectors")
    fi
done

if [ ${#problems[@]} -gt 0 ]; then
    msg=$(printf '%s; ' "${problems[@]}")
    echo "$msg" >&2
    curl -fsS -m 10 -X POST -H 'Content-Type: application/json' \
        -d "{\"message\": \"${msg%; }\"}" "$HA_WEBHOOK_URL" >/dev/null
    exit 1
fi
