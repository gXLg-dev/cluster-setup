# 1. boot up the raspberry pi
# 2. connect the SSD
# 3. cconnect over SSH
# 4. run this file

# update system and install needed libraries
sudo apt update
sudo apt upgrade -y
sudo apt install dnsmasq iptables dhcpcd5 nfs-kernel-server nodejs npm iptables-persistent -y
# select "no" two times when installing "iptables-persistent"


# save mountpoint for SSD
umo=$(lsblk -P | grep 'TYPE="part" MOUNTPOINTS=""' | grep -Eo '[a-z0-1]*?' | head -n 1)
mkdir -p ~/shared
sudo sh -c "echo '/dev/$umo  /home/$(whoami)/shared  auto  defaults  0  0' >> /etc/fstab"
sudo mount /dev/$umo /home/$(whoami)/shared
sudo chown $(whoami):$(whoami) /home/$(whoami)/shared
sudo chmod 755 /home/$(whoami)/shared

# disable wifi
sudo sh -c "echo 'dtoverlay=pi3-disable-wifi' >> /boot/firmware/config.txt"

# setup LAN sharing
lan=$(nmcli device status | grep -E "Wired connection 1" | cut -d " " -f 1)
new=$(nmcli device status | grep -E "ethernet[ ]+(connecting|disconnected)" | cut -d " " -f 1)
sudo sh -c "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf"
sudo sh -c "echo 'interface $new\nstatic ip_address=192.168.69.1/24\nnohook wpa_supplicant' >> /etc/dhcpcd.conf"
sudo sh -c "echo 'interface=$new\ndhcp-range=192.168.69.100,192.168.69.200,255.255.255.0,24h' >> /etc/dnsmasq.conf"
sudo iptables -t nat -A POSTROUTING -o $lan -j MASQUERADE
sudo iptables -A FORWARD -i $new -o $lan -j ACCEPT
sudo iptables -A FORWARD -i $lan -o $new -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo netfilter-persistent save

# setup NFS
sudo sh -c "echo '/home/$(whoami)/shared 192.168.69.1/24(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)' >> /etc/exports"
sudo systemctl enable nfs-kernel-server

# reboot
sudo reboot
