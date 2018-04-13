#!/bin/bash

# add two lines to the afni_proc.py generated scripts to set number of threads for 3dQwarp command
sourceScript=$1
threadNum_3dQwarp=$2
threadNum_new=$3

while read -r line
do
  thisLine="$line"
	# change thread numbers
  # if this line has 3dQwarp in it, add a line beforehand updating OMP thread #
	if [[ "$thisLine" == 3dQwarp* ]]
  then
    echo "found it!"
    echo "setenv OMP_NUM_THREADS $threadNum_3dQwarp" >> ${sourceScript}_edited
	fi

  # now write the line
  echo $thisLine >> ${sourceScript}_edited

  
  # if end of 3dQwarp command (ends in -prefix blip_warp*), reset thread nums
	# reset thread numbers
	if [[ "$thisLine" == *"-prefix blip_warp"* ]]
	then
    echo "resetting!"
    echo "setenv OMP_NUM_THREADS $threadNum_new" >> ${sourceScript}_edited
	fi

done < "$sourceScript"
