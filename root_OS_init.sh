# As root

echo "Are you root? Press enter if YES"

read user

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

read var

apt update && apt upgrade -y

read var

apt-get install -y \
    build-essential \
    pkg-config \
    libudev-dev llvm libclang-dev \
    protobuf-compiler libssl-dev

read var

adduser --ingroup sudo sol
addgroup sol
usermod -aG  sol sol

mkdir -p /mnt/ledger /mnt/accounts
chown -R sol:sol /mnt/ledger/ /mnt/accounts/

read var

lsblk -f

echo "First disk to format?: "
read disk1

mkfs -t ext4 /dev/$disk1

echo "Second disk to format?: "
read disk2

mkfs -t ext4 /dev/$disk2

UUID1=$(blkid -s UUID -o value /dev/$disk1) && echo $UUID1
UUID2=$(blkid -s UUID -o value /dev/$disk2) && echo $UUID2

cat >> /etc/fstab <<- EOM
UUID=$UUID1  /mnt/ledger  ext4  defaults  0  2
UUID=$UUID2  /mnt/accounts  ext4  defaults  0  2
EOM

tail /etc/fstab

read input

mount -a

#mount /dev/nvme0n1 /mnt/ledger
#mount /dev/nvme1n1 /mnt/accounts

df -h /mnt/*

read input

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

# Set CPU governor to performance mode
echo 'GOVERNOR="performance"' | tee /etc/default/cpufrequtils
echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set performance governor for bare metal (ignore errors)
echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor || true

echo
echo "Add this to [Manager] section: 
DefaultLimitNOFILE=1000000"
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
