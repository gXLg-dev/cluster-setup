# 1. Connect to PoE
# 2. Boot and run this script

# update system
sudo apt update
sudo apt upgrade -y

# install Node.js v20.19.5 (LTS)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 20.19.5
npm install -g npm@latest

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
ExecStart=/bin/bash -c "source /home/$(whoami)/.nvm/nvm.sh && node worker.js"
KillSignal=SIGINT
KillMode=process
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable gxlg-worker.service

# reboot
sudo reboot
