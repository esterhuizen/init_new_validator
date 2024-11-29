mkdir ~/validator_run_env/ 
cd ~/validator_run_env/

printf "Is this Testnet (t) or Mainnet (m) host?: "
read net

solana config set -u$net

solana-keygen new -o authorized-withdrawer-keypair.json --no-bip39-passphrase
solana-keygen new -o validator-keypair.json --no-bip39-passphrase
solana-keygen new -o vote-account-keypair.json --no-bip39-passphrase

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
