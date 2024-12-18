# 1. Connect to PoE
# 2. Boot and run this script

# update system
sudo apt update
sudo apt upgrade -y
sudo apt install nodejs npm -y

# disable wifi
sudo sh -c "echo 'dtoverlay=pi3-disable-wifi' >> /boot/firmware/config.txt"

# connecting to nfs
mkdir -p ~/shared
sudo sh -c "echo '192.168.69.1:/home/$(whoami)/shared  /home/$(whoami)/shared  nfs  rw,defaults,nofail,x-systemd.automount,vers=4,noatime  0  0' >> /etc/fstab"

# add worker to systemd
cat << EOF | sudo tee /etc/systemd/system/gxlg-worker.service
[Unit]
Description=gXLg Cluster Worker
After=network.target
RequiresMountsFor=/home/$(whoami)/shared

[Service]
User=$(whoami)
WorkingDirectory=/home/$(whoami)/shared/gxlg-cluster
ExecStart=/usr/bin/node worker.js

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable gxlg-worker.service

# reboot
sudo reboot
