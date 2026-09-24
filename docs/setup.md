# Setup from scratch

What I'd do if the SD card died tomorrow. Roughly in this order.

## 1. OS

- Raspberry Pi OS Lite 64-bit, flashed with Raspberry Pi Imager
  (set hostname `pi`, user, ssh key and locale directly in the imager)
- DHCP reservation for the pi on the Fritz!Box (Home Network > Network, edit the
  device, "Always assign this network device the same IPv4 address")

```sh
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git rsync smartmontools wireguard iptables qrencode nut
```

## 2. Disks

```sh
lsblk -f                       # find the UUIDs
sudo mkdir -p /mnt/hdd /mnt/backup
sudoedit /etc/fstab            # lines from system/fstab.example
sudo mount -a
```

`nofail` matters, see [incidents.md](incidents.md).

## 3. Docker

```sh
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cp system/docker-wait-for-hdd.conf /etc/systemd/system/docker.service.d/
sudo systemctl daemon-reload
```

## 4. Clone this repo and start the containers

```sh
sudo git clone https://github.com/AlessandroMuleo/HomeLab /opt/homelab
sudo chown -R $USER: /opt/homelab
cd /opt/homelab

cp .env.example .env                                   # fill in passwords
cp homeassistant/secrets.yaml.example homeassistant/secrets.yaml

sudo mkdir -p /srv/pihole /srv/nextcloud/html /srv/nextcloud/db /mnt/hdd/nextcloud
sudo chown 33:33 /mnt/hdd/nextcloud                    # www-data in the container

docker compose up -d
```

Nextcloud first start takes a few minutes on the pi. After that:

```sh
docker exec -u www-data nextcloud php occ background:cron
docker exec -u www-data nextcloud php occ maintenance:repair --include-expensive
docker exec -u www-data nextcloud php occ config:system:set default_phone_region --value=IT
```

If restoring instead of starting fresh, see [restore.md](restore.md) before `up -d`.

## 5. Fritz!Box DNS

Point the LAN at pi-hole, see [network.md](network.md#dns). Add the lists from
`pihole/adlists.txt` in the web UI (http://pihole.lan/admin).

## 6. WireGuard

```sh
sudo cp system/99-wireguard.conf /etc/sysctl.d/ && sudo sysctl --system

cd /etc/wireguard
umask 077
wg genkey | sudo tee server.key | wg pubkey | sudo tee server.pub
sudo cp /opt/homelab/wireguard/wg0.conf.example wg0.conf   # paste keys
sudo systemctl enable --now wg-quick@wg0
```

For each client: generate a key pair, add a `[Peer]` to wg0.conf, fill
`peer.conf.example`, and on the phone scan it with `qrencode -t ansiutf8 < phone.conf`.

Fritz!Box: Internet > Permit Access > Port Sharing, add the pi, UDP 51820.

## 7. UPS

```sh
sudo cp nut/nut.conf nut/ups.conf nut/upsd.conf /etc/nut/
sudo cp nut/upsd.users.example /etc/nut/upsd.users     # set passwords
sudo cp nut/upsmon.conf.example /etc/nut/upsmon.conf   # same upsmon password
sudo chown root:nut /etc/nut/* && sudo chmod 640 /etc/nut/*
sudo systemctl restart nut-server nut-monitor
upsc ups@localhost
```

Home Assistant: add the NUT integration, host `127.0.0.1`, user `homeassistant`.
The entities end up as `sensor.ups_*`, which the automations use.

## 8. Home Assistant

http://ha.lan:8123, create the user, install the companion app on the phone.
The notify service name in `automations.yaml` (`notify.mobile_app_telefono`)
comes from the phone's device name, change it if the phone changes.

Set the webhook id in `automations.yaml` and in `HA_WEBHOOK_URL` in `.env`
to the same random string.

## 9. Cron

```sh
sudo crontab scripts/crontab
sudo /opt/homelab/scripts/backup.sh      # first run by hand, takes a while
```
