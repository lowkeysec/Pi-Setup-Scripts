#!/bin/bash
# Idempotent nftables + IPv4 forwarding setup for Raspberry Pi with ZeroTier
# Includes sanity checks

set -euo pipefail
IFS=$'\n\t'

echo "🔄 Updating package list..."
sudo apt update -y

echo "📦 Installing nftables..."
sudo apt install -y nftables

# Wi-Fi interface (change if your Pi uses something else like wlan1)
WIFI_IF="wlan0"

echo "📝 Writing nftables rules to /etc/nftables.conf..."
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

echo "♻️ Reloading nftables rules..."
sudo nft -f /etc/nftables.conf

echo "📋 Active nftables ruleset:"
sudo nft list ruleset

echo "🔐 Enabling and starting nftables service..."
sudo systemctl enable nftables --now

echo "🌍 Enabling IPv4 forwarding..."
# Ensure the setting exists in sysctl.conf (uncomment or add)
if grep -q "^[#]*\s*net.ipv4.ip_forward" /etc/sysctl.conf; then
    sudo sed -i 's|^[#]*\s*net.ipv4.ip_forward.*|net.ipv4.ip_forward=1|' /etc/sysctl.conf
else
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
fi

# Apply changes immediately
sudo sysctl -p

# ✅ Sanity checks
echo "🔎 Sanity checks:"

# Check IPv4 forwarding status
IP_FORWARD=$(sysctl -n net.ipv4.ip_forward)
echo "IPv4 forwarding is set to: $IP_FORWARD"

# List ZeroTier interfaces
echo "Detected ZeroTier interfaces:"
ip -o link show | awk -F': ' '{print $2}' | grep '^zt' || echo "No ZeroTier interfaces detected"

# Optional: ping a ZeroTier network peer if known
# Uncomment and replace <peer_ip> with a reachable IP
# echo "Testing connectivity to ZeroTier peer <peer_ip>..."
# ping -c 3 <peer_ip>

echo "✅ nftables installation, configuration, and sanity checks complete."
