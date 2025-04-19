# 1. insert boot media, insert USB to LAN adapter
# 2. boot up the raspberry pi
# 3. connect the SSD
# 4. connect over SSH
# 5. run this file

# update system and install needed libraries
sudo apt update
sudo apt upgrade -y
sudo apt install nfs-kernel-server nodejs npm screen python3-pip -y

# save mountpoint for SSD
umo=$(lsblk -P | grep 'TYPE="part" MOUNTPOINTS=""' | grep -Eo '[a-z0-1]*?' | head -n 1)
mkdir -p ~/shared
sudo sh -c "echo '/dev/$umo  /home/$(whoami)/shared  auto  defaults  0  0' >> /etc/fstab"
sudo mount /dev/$umo /home/$(whoami)/shared
sudo chown $(whoami):$(whoami) /home/$(whoami)/shared
sudo chmod 755 /home/$(whoami)/shared

# disable wifi
sudo sh -c "echo 'dtoverlay=pi3-disable-wifi' >> /boot/firmware/config.txt"

# remove IPv6 (not supported with my router, but fake advertisement)
sudo sh -c 'echo -n "  ipv6.disable=1  " >> /boot/firmware/cmdline.txt'

# setup LAN sharing
usb=$(nmcli device status | grep -E "ethernet[ ]+(connecting|disconnected)" | cut -d " " -f 1)
sudo nmcli con add type ethernet ifname $usb con-name ClusterLAN ipv4.addresses 192.168.69.1/24 ipv4.method manual ipv6.method ignore
sudo nmcli con mod ClusterLAN ipv4.gateway "" ipv4.dns ""
sudo nmcli con mod ClusterLAN ipv4.method shared
sudo nmcli con up ClusterLAN

# setup NFS
sudo sh -c "echo '/home/$(whoami)/shared 192.168.69.1/24(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)' >> /etc/exports"
sudo systemctl enable nfs-kernel-server

# download cloudflared
mkdir -p ~/bin
curl "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" -o ~/bin/cloudflared
chmod +x ~/bin/cloudflared

# clone gxlg-cluster
cd shared
git clone https://github.com/gXLg-dev/gxlg-cluster
cd gxlg-cluster
npm ci

# WRITE THE CONFIG FILE AT THIS POINT
nano config.json

# reboot
sudo reboot
