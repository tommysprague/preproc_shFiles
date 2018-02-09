#!/bin/bash
#
# redo_preproc.sh
#
# for batch recomputing all necessary preprocessing steps (w/ improved unwarping)


# first, do this for task data....

ROOT=/deathstar/data

PROJECT=wmChoose_scanner

declare -a SUBJ=("EK") # "CC" "MR" "KD")
declare -a SESS=("MGSMap1" "MGSMap2")

for thissubj in "${SUBJ[@]}"; do

    mkdir $ROOT/$PROJECT/$thissubj/align_QC/orig

    for thissess in "${SESS[@]}"; do

        echo $thissubj $thissess

        # sessdir is where the actual session will live; origdir is where we move 'old' or 'orig' stuff
        SESSDIR=$ROOT/$PROJECT/$thissubj/$thissess
        ORIGDIR=$ROOT/$PROJECT/$thissubj/${thissess}_orig

        # first, rename current sess directory to SESS_orig
        echo moving $SESSDIR to $ORIGDIR
        mv $SESSDIR $ORIGDIR

        # make session dir again
        mkdir $SESSDIR

        # copy run??, blip_????, *_receive_field.nii.gz files from _orig to new, and _SEtarget.txt
        cp $ORIGDIR/run??.nii* $SESSDIR/
        cp $ORIGDIR/blip_for?.nii* $SESSDIR/
        cp $ORIGDIR/blip_rev?.nii* $SESSDIR/
        cp $ORIGDIR/*_receive_field.nii* $SESSDIR/
        cp $ORIGDIR/${thissubj}_${thissess}_SEtargets.txt $SESSDIR/

        # move SUBJ/align_QC/SUBJ_SESS_mu*.nii.gz to align_QC/old/*
        mv $ROOT/$PROJECT/$thissubj/align_QC/${thissubj}_${thissess}_* $ROOT/$PROJECT/$thissubj/align_QC/orig/

        # ~~~~ run preproc_task.sh ~~~~
        $PREPROC/preproc_task.sh $PROJECT $thissubj $thissess

        # clean up surf2vol tmp files
        rm $SESSDIR/?h_${thissubj}_${thissess}.r*_*.nii.gz

        # clean up uncompressed pb00 files (these are exactly _bc.nii.gz)
        rm $SESSDIR/*.results/pb00.*
        rm $ORIGDIR/*.results/pb00.*

        # in ORIGDIR, get rid of all pb files - these had already been converted to func, surf equivalents when necessary (saves ~20 GB/sess)
        rm $ORIGDIR/*.results/pb*.*

        # clean up run??.nii* in $ORIGDIR
        rm $ORIGDIR/run??.nii*
    done

done