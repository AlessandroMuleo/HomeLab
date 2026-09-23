# HomeLab

Notes on the home server I set up in 2021: a Raspberry Pi 4 (8 GB) behind a Fritz!Box, about 20 devices on the network.

What ran on it:
- Pi-hole as DNS for the whole LAN (set on the Fritz!Box, so no config needed on each device)
- WireGuard for remote access
- Home Assistant (Hass.io)
- Nextcloud, with the data on an external HDD

Home Assistant and Nextcloud were also exposed with port forwarding on the Fritz!Box, not only through the VPN. Only the WireGuard port really needed to be open.

A blackout killed the external HDD at some point. After that I added a UPS and started taking snapshots.

TODO: upload the configs once I've stripped keys and IPs.
