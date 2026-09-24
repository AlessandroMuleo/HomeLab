# HomeLab

Config and notes for the home server I set up in 2021 and still run: a Raspberry Pi 4 (8 GB)
behind a Fritz!Box, about 20 devices on the network.

What runs on it:
- Pi-hole as DNS for the whole LAN (set on the Fritz!Box, so no config needed on each device)
- WireGuard for remote access, the only port open from outside
- Home Assistant
- Nextcloud, with the data on an external HDD
- NUT for the UPS

Pi-hole, Home Assistant and Nextcloud run in docker (`docker-compose.yml`).
WireGuard and NUT run directly on the host.

Home Assistant and Nextcloud used to be exposed with port forwarding on the Fritz!Box,
not only through the VPN. Only the WireGuard port really needed to be open, so now
that's the only forward left.

A blackout killed the external HDD at some point. After that I added a UPS and started
taking snapshots to a second disk, see [docs/incidents.md](docs/incidents.md).

## Layout

```
docker-compose.yml   pi-hole, home assistant, nextcloud (+ mariadb, redis)
.env.example         passwords and paths, copy to .env
pihole/              adlists and allowlist (added via web UI)
homeassistant/       HA config dir, only the yaml is tracked
wireguard/           server and client config, keys removed
nut/                 UPS config, goes in /etc/nut
system/              fstab, systemd and sysctl bits
scripts/             backup, disk check, update, crontab
docs/                setup, network, restore, incidents
```

Files ending in `.example` have the keys/passwords replaced with placeholders.
The real ones are in `.gitignore`.

## Docs

- [setup.md](docs/setup.md): from a blank SD card to everything running
- [network.md](docs/network.md): addresses, ports, DNS, port forwarding
- [restore.md](docs/restore.md): getting things back from the snapshots
- [incidents.md](docs/incidents.md): what broke and what changed after

## TODO

- offsite backup (restic?)
- HTTPS for Nextcloud inside the LAN, it's plain http behind the VPN right now
- look into WireGuard on the Fritz!Box itself
- move the HA config off the SD card
