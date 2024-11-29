# for i in `cat servers.txt`; do echo $i | sed 's|https://||'; time curl $i; sleep 1; done

for i in `cat servers.txt`; do echo $i; time curl $i; echo ===========; sleep 1; done

