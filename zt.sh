#!/bin/bash
# Raspberry Pi post-install setup script

# Exit if any command fails
set -e

echo "Updating system..."
sudo apt-get update && sudo apt-get -y upgrade

echo "Adding ZeroTier GPG key..."
curl -fsSL https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/zerotierone-archive-keyring.gpg >/dev/null

echo "Adding ZeroTier repository..."
RELEASE=$(lsb_release -cs)
echo "deb [signed-by=/usr/share/keyrings/zerotierone-archive-keyring.gpg] http://download.zerotier.com/debian/$RELEASE $RELEASE main" \
  | sudo tee /etc/apt/sources.list.d/zerotier.list

echo "Updating apt again..."
sudo apt-get update

echo "Installing ZeroTier..."
sudo apt-get install -y zerotier-one

echo "Joining ZeroTier network..."
sudo zerotier-cli join 45b6e887e2ef8449

echo "Setup complete!"
