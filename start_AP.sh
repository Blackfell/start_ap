#!/bin/bash 

# Global config - beware, this goes into regex in a dumb way!
DEVICE=wlan0
WAN=eth0
SSID=blackfell
PASSPHRASE=trainer-glob-easter
PROXY=1     # 1 for HTTP only 2 for HTTPS too, 0 for none

# Shutdown stuff
function sthap() {
    echo "Stopping all the things"
    sudo killall dhcpd
    sudo killall hostapd
    sudo killall dnschef
    # Delete all rules for forwarding etc.
    sudo iptables -t nat -D POSTROUTING -s 10.69.42.0/24 -j MASQUERADE
    sudo iptables -D FORWARD --source 10.69.42.0/24 -j ACCEPT
    sudo iptables -D OUTPUT -m state --state ESTABLISHED -j ACCEPT
    sudo iptables -t nat -D PREROUTING -s 10.69.42.0/24 -p tcp --dport 80 -j DNAT --to-destination 10.69.42.1:9080
    sudo iptables -t nat -D PREROUTING -s 10.69.42.0/24 -p tcp --dport 443 -j DNAT --to-destination 10.69.42.1:9443
    # Port forward
    # Sort out config files
    for i in ./*.conf; do
        rm ./$i
        cp "./$i.bak" ./$i
    done
    #
    echo "K bye thx."
    exit
}

# Prep config files
for i in ./*.conf; do
    cp $i "./$i.bak"
    sed -i "s/SSID/$SSID/g" ./$i
    sed -i "s/PASSPHRASE/$PASSPHRASE/g" ./$i
    sed -i "s/DEVICE/$DEVICE/g" ./$i
    sed -i "s/WAN/$WAN/g" ./$i
done

# Prepare the wifi device
sudo nmcli radio wifi off
sudo rfkill unblock wlan

# Prepare IP forwarding
if sudo sysctl -w net.ipv4.ip_forward=1; then echo "";
else 
    sthap
fi
if sudo ifconfig $DEVICE up 10.69.42.1 netmask 255.255.255.0 ; then echo "";
else
    sthap
fi
sleep 1

#Doesn’t try to run dhcpd when already running 
if [[ “$(ps -e | grep dhcpd)” = “” ]]; then 
    echo "Starting DHCPD server"
    sudo dhcpd -cf $(pwd)/dhcpd.conf $DEVICE &
fi 

# Enable NAT, forwarding and outbound
sudo iptables -t nat -A POSTROUTING -s 10.69.42.0/24 -j MASQUERADE
sudo iptables -A FORWARD --source 10.69.42.0/24 -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT

# Start DNS
echo "[-] - Starting high visibilty DNS..."
sudo terminator -e 'dnschef -i 10.69.42.1' 2>/dev/null &
sleep 5
if pgrep -fx 'python3 /usr/bin/dnschef -i 10.69.42.1' > /dev/null  ; then
    echo "[+] DNS Chef started!"
else
    echo "[!] DNS Chef no start :( can't continue"
    sthap
fi

# Proxy traffic
if [[ $PROXY = 1 ]]; then
    echo "[-] - Proxying HTTP only. Tun burp transparent on port 9080"
    sudo iptables -t nat -I PREROUTING -s 10.69.42.0/24 -p tcp --dport 80 -j DNAT --to-destination 10.69.42.1:9080
elif  [[ $PROXY = 2 ]]; then
    echo "[-] - Proxying HTTP & HTTPS. Tun burp transparent on port 9080 & 9443"
    sudo iptables -t nat -I PREROUTING -s 10.69.42.0/24 -p tcp --dport 80 -j DNAT --to-destination 10.69.42.1:9080
    sudo iptables -t nat -I PREROUTING -s 10.69.42.0/24 -p tcp --dport 443 -j DNAT --to-destination 10.69.42.1:9443
else
    echo "[-] - NOT proxying web traffic."
fi

#start hostapd 
echo "Starting hostapd"
sleep 1 
sudo terminator -e "hostapd $(pwd)/hostapd.conf" 2>/dev/null &
sleep 4

KEY="NO"
while $true; do
    if [ "$KEY" = "q" ]; then break; fi
    read -p "Press q to exit! ($KEY) " -n 1 KEY
done
echo "[!] - Stopping. Bye."
sthap
