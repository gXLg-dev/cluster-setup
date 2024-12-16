# 1. Connect to PoE
# 2. Boot and run this script

# update system
sudo apt update
sudo apt upgrade -y
sudo apt install nodejs npm firejail -y

# disable wifi
sudo sh -c "echo 'dtoverlay=pi3-disable-wifi' >> /boot/firmware/config.txt"

# connecting to nfs
mkdir -p ~/shared
sudo sh -c "echo '192.168.69.1:/home/$(whoami)/shared  /home/$(whoami)/shared  nfs  rw,defaults,nofail,x-systemd.automount,vers=4,noatime  0  0' >> /etc/fstab"

# reboot
sudo reboot
