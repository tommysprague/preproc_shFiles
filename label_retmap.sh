#!/bin/bash

# write labels for AFNI briks (for RF maps, for example)
#
# Run like preproc_RF.sh:
# $PREPROC/label_retmap.sh vRF_tcs CC RF1
# 
# Will try to generate ss5, surf, func, ss5_25mm and func_25mm maps - if these aren't found, errors will be spit out, but script will run
#
# NOTE: does not overwrite, so if you re-run model fits, need to manually delete .nii.gz files in RETRDIR


RFDIR=$1
SUBJ=$2
SESS=$3
vistaDir=/deathstar/data/$RFDIR/$SUBJ/$SESS/${SUBJ}_${SESS}_vista
RFdir=$vistaDir/Inplane/Original   # where the RF files are saved, incl. nii.gz (raw)

declare -a RF_prefix=("RF_ss5" "RF_surf" "RF_func" "RF_surf_25mm" "RF_func_25mm")
declare -a RF_suffix=("gFit" "sFit" "fFit")

for p in "${RF_prefix[@]}"; do


  for s in "${RF_suffix[@]}"; do

    #TODO: if this file exists, use it, otherwise, use a default set (in comments below)
    labels=`cat $RFdir/${p}-${s}_params.txt` #"VE phase ecc size exp x0 y0 b"


    # USE AFNI to load RF file, save a brik/head, label, convert to nii, delete intermed. files

    # copy as BRIK/HEAD
    3dcopy $RFdir/${p}-${s}.nii.gz $RFdir/${p}-${s}+orig

    # apply "labels" to each brik (should probably check right # of briks, etc...)
    3drefit -relabel_all_str "$labels" $RFdir/${p}-${s}+orig

    # copy the result to vistaDir for visualization!
    3dcopy $RFdir/${p}-${s}+orig $vistaDir/${p}-${s}.nii.gz



    # clean intermediate files
    rm $RFdir/*.BRIK
    rm $RFdir/*.HEAD


  done
done
