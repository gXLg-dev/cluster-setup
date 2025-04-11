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

cat << EOF | sudo tee /etc/systemd/system/wait-for-network.service
[Unit]
Description=Wait for local network

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'until ping -c1 192.168.69.1; do sleep 1; done'

[Install]
WantedBy=nfs-client.target
EOF
sudo systemctl enable wait-for-network.service

cat << EOF | sudo tee /etc/systemd/system/home-$(whoami)-shared.mount
[Unit]
Description=Mount NFS
After=NetworkManager-wait-online.service
Requires=NetworkManager-wait-online.service

[Mount]
What=192.168.69.1:/home/$(whoami)/shared
Where=/home/$(whoami)/shared
Type=nfs
Options=rw,defaults,noatime,vers=4

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable home-$(whoami)-shared.mount

# add worker to systemd
cat << EOF | sudo tee /etc/systemd/system/gxlg-worker.service
[Unit]
Description=gXLg Cluster Worker
After=home-$(whoami)-shared.mount
Requires=home-$(whoami)-shared.mount

[Service]
User=$(whoami)
WorkingDirectory=/home/$(whoami)/shared/gxlg-cluster
ExecStart=/usr/bin/node worker.js
KillSignal=SIGINT
KillMode=process
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable gxlg-worker.service

# reboot
sudo reboot
