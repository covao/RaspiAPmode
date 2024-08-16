#!/bin/bash

# Restore wlan0 to managed mode and disable AP mode

# Stop hostapd and dnsmasq services
echo "Stopping hostapd and dnsmasq services..."
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Remove hostapd configuration
echo "Removing hostapd configuration..."
sudo rm -f /etc/hostapd/hostapd.conf
sudo sed -i '/DAEMON_CONF/d' /etc/default/hostapd

# Restore original dnsmasq configuration
echo "Restoring dnsmasq configuration..."
if [ -f /etc/dnsmasq.conf.orig ]; then
  sudo mv /etc/dnsmasq.conf.orig /etc/dnsmasq.conf
fi

# Disable IP forwarding
echo "Disabling IP forwarding..."
sudo sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
sudo sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward"

# Remove NAT iptables rule
echo "Removing NAT iptables rule..."
sudo iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables/rules.v4"

# Restart dhcpcd service
echo "Restarting dhcpcd service..."
sudo systemctl restart dhcpcd

# Start wpa_supplicant for wlan0 (restore normal Wi-Fi mode)
echo "Restoring wpa_supplicant for normal Wi-Fi mode..."
sudo systemctl unmask wpa_supplicant
sudo systemctl enable wpa_supplicant
sudo systemctl start wpa_supplicant

echo "Wi-Fi restored to normal mode."
