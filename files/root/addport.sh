#!/bin/bash

FILE="/etc/board.json"

jq '.network.wan = {
  ports: ["eth1", "usb0"],
  protocol: "dhcp"
}' "$FILE" > /tmp/board.json && mv /tmp/board.json "$FILE"

rm -- "$0"
