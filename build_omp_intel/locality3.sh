#!/bin/bash


PLATFORM=SKX
outfile=skylake_locality.txt

rm -f $outfile tmp1.txt tmp2.txt

for s in 1 2 4 8 16 32 64 128;
do
	for loc in 0 .1 .2 .3 .4 .5 .6 .7 .8 .9 1;
	do
		echo "Running sparsity $s, locailty $loc"
		rm -f tmp1.txt tmp2.txt
		for i in `seq 1 10`; 
		do 
			OMP_NUM_THREADS=1 likwid-pin -c N:0 ./spatter -b openmp -s $s -q -R 20 --no-print-header -l 4000000 -L $loc | cut -d' ' -f10 >> tmp1.txt 
			OMP_NUM_THREADS=1 likwid-pin -c N:0 ./spatter -b serial -s $s -q -R 20 --no-print-header -l 4000000 -L $loc | cut -d' ' -f10 >> tmp2.txt 
		done;
		vec=`sort -nr tmp1.txt | head -n1`
		sca=`sort -nr tmp2.txt | head -n1`
		math=`perl -e "print $vec / $sca * 100 - 100"`
		echo "$PLATFORM $s $loc $math" >> $outfile
		#pct=`echo print $vec/$sca * 100 - 100 | perl`
		#echo "pct:"$pct
		

	done;
done;

rm -f tmp1.txt tmp2.txt

echo $outfile
cat $outfile


# "2568.035417 / 2561.595498 * 100 - 100
