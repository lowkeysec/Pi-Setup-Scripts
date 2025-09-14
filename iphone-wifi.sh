#!/bin/bash
# Setup WiFi connection with NetworkManager
# Usage:
#   curl -sSL https://raw.githubusercontent.com/<user>/<repo>/main/iphone.sh | sudo bash -s "SSID" "PASSWORD"

set -e

SSID="$1"
PSK="$2"

if [ -z "$SSID" ] || [ -z "$PSK" ]; then
  echo "❌ Usage: $0 <SSID> <PASSWORD>"
  exit 1
fi

CONFIG_PATH="/etc/NetworkManager/system-connections/${SSID}.nmconnection"

echo "📡 Setting up NetworkManager WiFi connection for SSID: $SSID"

# Generate a UUID
UUID=$(uuidgen)

# Create the nmconnection file
sudo tee "$CONFIG_PATH" > /dev/null <<EOF
[connection]
id=${SSID}_wifi
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
echo "➡️ You can now connect with: nmcli connection up ${SSID}_wifi"

# Set proconfig wifi prioroty
sudo nmcli connection modify "preconfigured" connection.autoconnect-priority 1
echo "The preconfigured wifi is now set to priority 1."
