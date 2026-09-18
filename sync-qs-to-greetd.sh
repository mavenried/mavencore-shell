#!/bin/bash
set -euo pipefail

SRC="$HOME/.config/quickshell/greeter/"
DST="/etc/greetd/quickshell/"

sudo mkdir /var/lib/greetd/ &


sudo mkdir -p "$DST"
sudo rsync -a --delete "$SRC" "$DST"
