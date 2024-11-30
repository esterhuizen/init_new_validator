#!/bin/bash

# Install Solana

echo "look here https://github.com/jito-foundation/jito-solana/releases"
echo

printf "What version of jito?: "
read TAG
export $TAG
export TAG=v2.0.15-jito
git clone https://github.com/jito-foundation/jito-solana.git --recurse-submodules
cd jito-solana
git checkout tags/$TAG
git submodule update --init --recursive
CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only ~/.local/share/solana/install/releases/"$TAG"
