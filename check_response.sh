# for i in `cat servers.txt`; do echo $i | sed 's|https://||'; time curl $i; sleep 1; done

serverf=$(dirname $0)/servers.txt

for i in `cat $serverf`; do echo $i; time curl $i; echo ===========; sleep 1; done

