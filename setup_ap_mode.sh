#!/bin/bash

# Variables for AP settings
WIFI_MODE="5GHz"  # Wi-Fi mode, can be 2.4GHz or 5GHz
CHANNEL="36"      # Wi-Fi channel, 36 for 5GHz
SSID="TatamiRacer" # SSID of the access point
PASSWORD="raspberry" # Password for the access point
STATIC_IP="192.168.1.101" # Static IP address for Raspberry Pi

# Install necessary packages if they are not installed
echo "Installing necessary packages..."
sudo apt-get update -y
sudo apt-get install -y hostapd dnsmasq

# Stop services if they are running
echo "Stopping hostapd and dnsmasq services..."
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Configure static IP address
echo "Configuring static IP address..."
sudo sed -i '/interface wlan0/d' /etc/dhcpcd.conf
sudo sed -i '/static ip_address/d' /etc/dhcpcd.conf
echo "interface wlan0" | sudo tee -a /etc/dhcpcd.conf
echo "static ip_address=$STATIC_IP/24" | sudo tee -a /etc/dhcpcd.conf
sudo systemctl restart dhcpcd

# Create hostapd configuration
echo "Configuring hostapd..."
if [ ! -d "/etc/hostapd" ]; then
  sudo mkdir -p /etc/hostapd
fi
cat <<EOL | sudo tee /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
ssid=$SSID
hw_mode=a
channel=$CHANNEL
ieee80211n=1
ieee80211ac=1
wmm_enabled=1
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOL

# Set hostapd configuration file location
sudo sed -i '/DAEMON_CONF/d' /etc/default/hostapd
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' | sudo tee -a /etc/default/hostapd

# Configure dnsmasq
echo "Configuring dnsmasq..."
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cat <<EOL | sudo tee /etc/dnsmasq.conf
interface=wlan0
dhcp-range=192.168.1.50,192.168.1.150,255.255.255.0,24h
EOL

# Enable IP forwarding
echo "Enabling IP forwarding..."
sudo sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# Configure NAT with iptables
echo "Configuring NAT with iptables..."
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables/rules.v4"

# Start services
echo "Starting hostapd and dnsmasq services..."
sudo systemctl start hostapd
sudo systemctl start dnsmasq

# Check status of hostapd
echo "Checking hostapd status..."
sudo systemctl status hostapd --no-pager
