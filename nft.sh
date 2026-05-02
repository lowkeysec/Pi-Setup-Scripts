#!/bin/bash
# Raspberry Pi nftables setup script
# Idempotent and safe to re-run
# curl -sSL https://raw.githubusercontent.com/lowkeysec/Pi-Setup-Scripts/refs/heads/main/nft.sh | sudo bash

set -euo pipefail
IFS=$'\n\t'


### --- nftables Installation ---
echo "Installing nftables..."
sudo apt-get install -y nftables

# Wi-Fi interface (adjust if your Pi uses wlan1, etc.)
WIFI_IF="wlan0"

echo "Writing nftables rules to /etc/nftables.conf..."
sudo tee /etc/nftables.conf > /dev/null << EOF
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0;
        policy accept;
    }

    chain forward {
        type filter hook forward priority 0;
        policy drop;

        # allow established/related traffic
        ct state established,related accept

        # allow ZeroTier -> Wi-Fi
        iifname "zt*" oifname "$WIFI_IF" accept

        # allow Wi-Fi -> ZeroTier
        iifname "$WIFI_IF" oifname "zt*" accept
    }

    chain output {
        type filter hook output priority 0;
        policy accept;
    }
}

table ip nat {
    chain postrouting {
        type nat hook postrouting priority 100;
        # Masquerade ZeroTier traffic going out Wi-Fi
        oifname "$WIFI_IF" masquerade
    }
}
EOF

echo "Reloading nftables rules..."
sudo nft -f /etc/nftables.conf

echo "Active nftables ruleset:"
sudo nft list ruleset

echo "Enabling nftables service..."
sudo systemctl enable nftables --now

### --- Enable IPv4 Forwarding ---
echo "Enabling IPv4 forwarding..."
if grep -q "^[#]*\s*net.ipv4.ip_forward" /etc/sysctl.conf; then
    sudo sed -i 's|^[#]*\s*net.ipv4.ip_forward.*|net.ipv4.ip_forward=1|' /etc/sysctl.conf
else
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
fi

sudo sysctl -p

### --- Sanity Checks ---
echo "Running sanity checks..."

# IPv4 forwarding status
IP_FORWARD=$(sysctl -n net.ipv4.ip_forward)
echo "IPv4 forwarding is set to: $IP_FORWARD"

# ZeroTier interfaces
ZT_IFS=$(ip -o link show | awk -F': ' '{print $2}' | grep '^zt' || true)
if [[ -n "$ZT_IFS" ]]; then
    echo "Detected ZeroTier interfaces:"
    echo "$ZT_IFS"
else
    echo "No ZeroTier interfaces detected yet. (ZeroTier may still be starting)"
fi

echo "Setup complete: ZeroTier + nftables are installed and configured."
