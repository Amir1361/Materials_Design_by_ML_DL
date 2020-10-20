#!/bin/bash

cr=(0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45)
co=(0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45)
temp=(873 893 913 933 953 973)
tol=0.001
for t in {0..5} ##temperature
do
	for i in {0..7} ## cCr
	do
		for j in {0..7} ##cCo
		do
			mkdir run_cr${cr[$i]}_co${co[$j]}_T${temp[$t]}
                	cp -R build include Makefile scripts test doc lib README.md demo_bash-opt LICENSE run_tests src ./run_cr${cr[$i]}_co${co[$j]}_T${temp[$t]}
                	cd run_cr${cr[$i]}_co${co[$j]}_T${temp[$t]}
                	## rename the input file
                	## mv FeCrCo_TM.i FeCrCo_cr${cr[i]}_co${co[j]}_TM.i
                	## rename the application file
                	## mv different_composition-opt composition_cr${cr[i]}_co${co[j]}-opt
                	## min and max for Cr and Co compositions
                	##crmin=echo '${cr[$i]} - $tol' | bc -l
                	##K=$(echo ${cr[$i]} + $tol | bc)
                	##echo $K
                	crmin=$(echo ${cr[$i]} - $tol | bc)
                	crmax=$(echo ${cr[$i]} + $tol | bc)
                	comin=$(echo ${co[$j]} - $tol | bc)
                	comax=$(echo ${co[$j]} + $tol | bc)
       			## substitute in composition
               		## sed "s/ccr/${cr[$i]}/g;s/cco/${co[$j]}/g" <../FeCrCo_TM.i >FeCrCo_cr${cr[$i]}_co${co[$j]}_TM.i
                	sed "s/TTT/${temp[$t]}/g;s/crmin/$crmin/g;s/crmax/$crmax/g;s/comin/$comin/g;s/comax/$comax/g" <../FeCrCo.i >FeCrCo_cr${cr[$i]}_co${co[$j]}_T${temp[$t]}.i
                	## substitute the input and application file in slurm
                	sed "s/FeCrCo.i/FeCrCo_cr${cr[$i]}_co${co[$j]}_T${temp[$t]}.i/g" <../slurm-batch.bash>slurm-batch.bash
                	## submit job to cluster
                	sbatch slurm-batch.bash
                	cd ..
        	done ## end j loop
	done ## end i loop
done ##end t loop
