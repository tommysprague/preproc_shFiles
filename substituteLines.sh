#!/bin/sh

# add two lines to the afni_proc.py generated scripts to set number of threads for 3dQwarp command
sourceScript=$1
threadNum_3dQwarp=$2
threadNum_new=$3

while read -r line
do
    thisLine="$line"
	# change thread numbers
	if [[ $thisLine != *"3dQwarp -plusminus"* ]]
	then
		echo $thisLine >> ${sourceScript}_edited
	else
		echo "export OMP_NUM_THREADS=$threadNum_3dQwarp" >> ${sourceScript}_edited
		echo $thisLine >> ${sourceScript}_edited
	fi
	
	# reset thread numbers
	if [[ $thisLine != *"-prefix blip_warp"* ]]
	then
		echo $thisLine >> ${sourceScript}_edited
	else
		echo $thisLine >> ${sourceScript}_edited
		echo "export OMP_NUM_THREADS=$threadNum_new" >> ${sourceScript}_edited
	fi

done < "$sourceScript"

