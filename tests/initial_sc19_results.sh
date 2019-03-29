#/bin/bash

for f in `ls ../traces/*.pat`; do 
	echo -n "TRACE FILE: "
	echo $f
	./spatter -l $((2**17)) -t $f -b OpenMP -k GATHER -R 20 -q
done
