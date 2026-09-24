#!/usr/bin/env bash
# Run by hand, not from cron: I want to read the home assistant release notes
# before it updates, breaking changes happen.
set -euo pipefail

cd "$(dirname "$0")/.."

sudo apt-get update
sudo apt-get -y upgrade

docker compose pull
docker compose up -d
docker image prune -f

# nextcloud sometimes needs this after a major version
docker exec -u www-data nextcloud php occ db:add-missing-indices || true

if [ -f /var/run/reboot-required ]; then
    echo "reboot required"
fi
