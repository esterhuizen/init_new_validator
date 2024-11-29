
bdir=/home/sol/validator_run_env/bin
ldir=/home/sol/validator_run_env/log

mkdir $bdir $ldir

mv start-mainnet-jito-NY.sh-2.0.15 $bdir
mv stop-validator.sh $bdir

chmod 700 $bdir/*

./check_response.sh
