#!/bin/bash
# Setup iPhone WiFi connection with NetworkManager
# Safe to run multiple times (idempotent)

set -e

CONFIG_PATH="/etc/NetworkManager/system-connections/iPhone.nmconnection"
SSID="iPhone"
PSK="11110000"

echo "📡 Setting up NetworkManager WiFi connection for SSID: $SSID"

# Generate a UUID
UUID=$(uuid)

# Create the nmconnection file
sudo tee "$CONFIG_PATH" > /dev/null <<EOF
[connection]
id=iphone_wifi
uuid=$UUID
type=wifi
autoconnect=true
autoconnect-priority=3

[wifi]
mode=infrastructure
ssid=$SSID

[wifi-security]
key-mgmt=wpa-psk
psk=$PSK

[ipv4]
method=auto

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
EOF

# Set secure permissions
sudo chmod 600 "$CONFIG_PATH"

echo "✅ WiFi profile created: $CONFIG_PATH"
echo "➡️ You can now connect with: nmcli connection up iphone_wifi"

# Set proconfig wifi prioroty
sudo nmcli connection modify "preconfigured" connection.autoconnect-priority 1
echo "Preconfig Wifi set to lowest priority."
