# Network

```
                 internet
                    |
             +-------------+
             |  Fritz!Box  |  192.168.178.1
             |  DHCP       |  only 51820/udp forwarded -> pi
             +-------------+
                    |
        +-----------+--------------------+
        |           |                    |
  +-----------+   wifi / lan         (~20 devices:
  |   pi 4    |     clients           phones, laptops, tv,
  | .178.2    |                       plugs, printer...)
  +-----------+
   | usb        \ usb
 [HDD]         [UPS]
 [backup HDD]

  wg0 10.8.0.0/24  (phone .2, laptop .3)
```

## Addresses

| what        | ip              | notes                           |
|-------------|-----------------|---------------------------------|
| Fritz!Box   | 192.168.178.1   | gateway                         |
| pi          | 192.168.178.2   | fixed via DHCP reservation      |
| wireguard   | 10.8.0.0/24     | server is 10.8.0.1              |

Local names (served by pi-hole, see `FTLCONF_dns_hosts` in docker-compose.yml):
`pi.lan`, `pihole.lan`, `cloud.lan`, `ha.lan`, all pointing to the pi.

## Ports on the pi

| port       | service                |
|------------|------------------------|
| 53         | pi-hole DNS            |
| 80         | pi-hole web            |
| 8080       | nextcloud              |
| 8123       | home assistant         |
| 51820/udp  | wireguard              |
| 3493       | NUT (localhost only)   |

## DNS

Fritz!Box hands out the pi as DNS server via DHCP:
Home Network > Network > Network Settings > IPv4 Settings > Local DNS server = 192.168.178.2

The pi itself uses the Fritz!Box as upstream only for its own resolution
(so it can still pull images if the pihole container is down).

Pi-hole forwards to Quad9 and Cloudflare.

**IPv6 gotcha:** the Fritz!Box also announces itself as DNS server over IPv6
(router advertisements), and some clients (android mostly) prefer that and skip
pi-hole completely. Fix: Home Network > Network > Network Settings > IPv6 Settings,
set "Other IPv6 DNS server" / uncheck announcing the Fritz!Box as DNS. Easiest way
to check is the pi-hole query log: if a device never shows up, that's the reason.

## Port forwarding

At the beginning I forwarded Home Assistant and Nextcloud directly
from the Fritz!Box, so they were reachable from outside without the VPN.
That was a bad idea: two web apps open to the whole internet, for no real reason.
Now the only forward is 51820/udp for WireGuard, everything else goes through the VPN.

The endpoint for clients is the MyFRITZ! address, so the changing public IP
is not a problem.

TODO: FRITZ!OS 7.50+ can do WireGuard itself. Could move the VPN there and
close the last forward, but then the pi-hole DNS for VPN clients needs another
look.
