#!/bin/bash

# make_surf_mask.sh
#
# creates a binary mask from concatenated surf*mean runs (after preproc)

DATAROOT=/deathstar/data

EXPTDIR=$1
SUBJ=$2
SESS=$3

# concatenate
3dTcat -prefix $DATAROOT/$EXPTDIR/$SUBJ/$SESS/surf_volreg_mean_all.nii.gz $DATAROOT/$EXPTDIR/$SUBJ/$SESS/surf_volreg_mean*.nii.gz

# compute mask
3dAutomask -prefix $DATAROOT/$EXPTDIR/$SUBJ/$SESS/surf_mask.nii.gz $DATAROOT/$EXPTDIR/$SUBJ/$SESS/surf_volreg_mean_all.nii.gz
