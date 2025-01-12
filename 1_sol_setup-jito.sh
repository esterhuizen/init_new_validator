curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
rustup component add rustfmt
rustup update
sudo apt-get update
sudo apt-get install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler
echo

git clone https://github.com/jito-foundation/jito-solana.git --recurse-submodules
cd jito-solana
git tag
printf "What version of jito?: "
read TAG
echo
echo $TAG
echo "Is it correct?"
read input
git checkout tags/$TAG
git submodule update --init --recursive
CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only ~/.local/share/solana/install/releases/"$TAG"

echo
printf "what should be appended to .profile?: "
read top

echo $top >> ~/.profile
vi ~/.profile
. ~/.profile

mkdir ~/validator_run_env/ 

bdir=/home/sol/validator_run_env/bin
ldir=/home/sol/validator_run_env/log
mkdir $bdir $ldir

cp start-mainnet-jito-NY.sh-2.0.15 $bdir
cp stop-validator.sh $bdir
cp check_response.sh $bdir

chmod 700 $bdir/*

cd ~/validator_run_env/

printf "Is this Testnet (t) or Mainnet (m) host?: "
read net

solana config set -u$net

solana-keygen new -o authorized-withdrawer-keypair.json --no-bip39-passphrase | tee -a seed_backups
solana-keygen new -o validator-keypair.json --no-bip39-passphrase | tee -a seed_backups
solana-keygen new -o vote-account-keypair.json --no-bip39-passphrase | tee -a seed_backups

solana config set --keypair /home/sol/validator_run_env/validator-keypair.json

printf "What is the ID (above)?: "
read vid

cat >> ~/.profile <<- EOM
# Helpful Aliases
alias catchup='solana catchup --our-localhost'
alias monitor='agave-validator --ledger /mnt/ledger monitor'
alias logtail='tail -f  /home/sol/validator_run_env/log/solana-validator.log'

alias gossip='solana gossip | grep $vid'
alias validators='solana validators | grep $vid'
EOM



printf "Have you deposited SOL into id wallet ( $vid )?: "
read input

solana create-vote-account -u$net \
    --fee-payer ./validator-keypair.json \
    --commission 0 \
    ./vote-account-keypair.json \
    ./validator-keypair.json \
    ./authorized-withdrawer-keypair.json


$bdir/check_response.sh

echo "Check here for selecting: https://docs.jito.wtf/lowlatencytxnsend/#api"
echo "Go edit the startup script"
read input

echo "creating watchtower script"
cat >watchtower.sh <<EOF
#!/bin/bash
PATH=/home/solana/.local/share/solana/install/active_release/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

exec &gt;>watchtower.log \\
  env PAGERDUTY_INTEGRATION_KEY=<PAGERDUTY_KEY> \\
solana-watchtower \\
  --validator-identity <IDENTITY_PUBKEY> \\
  --monitor-active-stake \\
  --interval 20 \\
  --minimum-validator-identity-balance 3 \\
  --url https://api.testnet.solana.com
EOF

echo "See setup guide for Telegram: https://docs.anza.xyz/operations/best-practices/monitoring/#setup-telegram-notifications"
