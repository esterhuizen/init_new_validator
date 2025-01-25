#!/bin/bash

# As root
read -p "Are you root? Press enter if YES" input

# FW Firewall confir
ufw allow 22/tcp
ufw allow 8000:8020/tcp
ufw allow 8000:8020/udp
ufw allow 11228/udp
ufw allow 11229/udp
ufw allow from 127.0.0.1 to 127.0.0.1 port 8900
ufw allow from 127.0.0.1 to 127.0.0.1 port 8000
ufw allow from 127.0.0.1 to 127.0.0.1 port 8899
ufw enable

read -p "Enter to continue" input

apt update && apt upgrade -y

read -p "Enter to continue" input

apt-get install -y \
    build-essential \
    pkg-config \
    libudev-dev llvm libclang-dev \
    protobuf-compiler libssl-dev cpufrequtils

read -p "Enter to continue" input

adduser --ingroup sudo sol
addgroup sol
usermod -aG  sol sol

mkdir -p /mnt/ledger /mnt/accounts /mnt/snapshots /mnt/accounts_hash /mnt/accounts_index
chown -R sol:sol /mnt/ledger/ /mnt/accounts/ /mnt/snapshots /mnt/accounts_hash /mnt/accounts_index

cat >> /etc/fstab <<- EOM
tmpfs   /mnt/accounts_hash      tmpfs   defaults,noatime,size=256G   0   0
tmpfs   /mnt/accounts_index      tmpfs   defaults,noatime,size=256G   0   0
EOM

while true; do
    lsblk -f
    # Prompt the user for input
    read -p "Enter disk name to format (or 'x' to exit): " disk

    # Check if the input is 'x'
    if [ "$disk" == "x" ]; then
        echo "No more disks, continuing..."
        break
    fi

    mkfs -t ext4 /dev/$disk
    UUID1=$(blkid -s UUID -o value /dev/$disk) && echo $UUID1
    read -p "Mount point to use for this disk?: " mountp
    cat >> /etc/fstab <<- EOM
UUID=$UUID1  $mountp  ext4  defaults,noatime  0  2
EOM
    # sleep 1
done


tail /etc/fstab

read -p "Enter to continue" input

mount -a

df -h /mnt/*

read -p "Enter to continue" input

echo 'GOVERNOR="performance"' | tee /etc/default/cpufrequtils
systemctl restart cpufrequtils
 
# Set sysctl performance variables
cat >> /etc/sysctl.conf <<- EOM
# TCP Buffer Sizes (10k min, 87.38k default, 12M max)
net.ipv4.tcp_rmem=10240 87380 12582912
net.ipv4.tcp_wmem=10240 87380 12582912

# TCP Optimization
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_moderate_rcvbuf=1

# Kernel Optimization
kernel.timer_migration=0
kernel.hung_task_timeout_secs=30
kernel.pid_max=49152

# Virtual Memory Tuning
vm.swappiness=0
vm.max_map_count=2000000
vm.stat_interval=10
vm.dirty_ratio=40
vm.dirty_background_ratio=10
vm.min_free_kbytes=3000000
vm.dirty_expire_centisecs=36000
vm.dirty_writeback_centisecs=3000
vm.dirtytime_expire_seconds=43200

# Solana Specific Tuning
net.core.rmem_max=134217728
net.core.rmem_default=134217728
net.core.wmem_max=134217728
net.core.wmem_default=134217728
EOM

# Reload sysctl settings
sysctl -p

echo
echo "Add this to [Manager] section: 
DefaultLimitNOFILE=2000000"
read input
vi /etc/systemd/system.conf

echo
echo "Once your pubkey login works over ssh, check/set this in the sshd file:
PasswordAuthentication no
ChallengeResponseAuthentication no"
sudo grep PasswordAuthentication /etc/ssh/sshd_config
sudo grep ChallengeResponseAuthentication /etc/ssh/sshd_config
echo "are they correct?"
read input
vi /etc/ssh/sshd_config

apt install fail2ban
systemctl start fail2ban
systemctl enable fail2ban
systemctl status fail2ban

echo 
echo "Set swappiness to 0. Current value is:"
cat /proc/sys/vm/swappiness
# sudo sysctl vm.swappiness=0
# echo 
# echo "New value is: "
# cat /proc/sys/vm/swappiness
# echo "edit this line: vm.swappiness=0"
# read input

# vi /etc/sysctl.conf

echo -p "Add this: GRUB_CMDLINE_LINUX_DEFAULT=\"quiet nvme_core.default_ps_max_latency_us=0 pcie_aspm=off amd_pstate=passive nohz_full=2,26 isolcpus=domain,managed_irq,2,26 irqaffinity=0-1,3-25,27-47\"" input

vi /etc/default/grub
update-grub

echo "Checking NVMe link speeds: \n"

for pci_addr in $(lspci | grep -i nvme | awk '{print $1}'); do
        echo $pci_addr=====================
    lspci -s $pci_addr -vv | grep -i speed
done

