#!/bin/bash
# prep_anat.sh
#
# Use this to set up symlink to processed freesurfer directory, and create surfanat files
# used for retinotopy. Run once per subj folder within an expt directory (not for each sess)
#
# Requires a pre-processed file already (need to sample on that grid)




DATAROOT=/deathstar/data

EXPTDIR=$1

SUBJ=$2
ANATSUBJ=${SUBJ}anat
SESS=$3

# make symlink to freesurfer directory
#ln -s ../../fs_subjects/$ANATSUBJ $EXPTDIR/$SUBJ/$ANATSUBJ

# first preproc directorY: ls -d KD_RF1_r*_SEalign.results | head -1

# make surfanat files in $EXPTDIR/$SUBJ

#PREPROC_DIR=$(ls -d $EXPTDIR/$SUBJ/*/${SUBJ}_*r*_SEalign.results | head -1)
PREPROC_DIR=$(ls -d $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_*r*_SEalign.results | head -1)
PREPROC_IMG=$(ls $PREPROC_DIR/pb02.*.volreg+orig.BRIK | head -1)

3dresample -prefix $DATAROOT/$EXPTDIR/$SUBJ/surfanat_brainmask_master.nii.gz -master $PREPROC_IMG -rmode Cu -inset $DATAROOT/$EXPTDIR/$SUBJ/$ANATSUBJ/SUMA/brainmask.nii
3dresample -prefix $DATAROOT/$EXPTDIR/$SUBJ/surfanat_brainmask_master.nii.gz -orient rai -overwrite -inset $DATAROOT/$EXPTDIR/$SUBJ/surfanat_brainmask_master.nii.gz
#3dresample -prefix $EXPTDIR/$SUBJ/surfanat_brainmask_master_25mm.nii.gz -master $PREPROC_IMG -rmode Cu -inset $SUBJECTS_DIR/$ANATSUBJ/SUMA/brainmask.nii

3dresample -prefix $DATAROOT/$EXPTDIR/$SUBJ/surfanat_brainmask_hires.nii.gz -dxyz 1.0 1.0 2.0 -rmode Cu -orient RAI -inset $DATAROOT/$EXPTDIR/$SUBJ/surfanat_brainmask_master.nii.gz
=======
#3dresample -prefix $DATAROOT/$EXPTDIR/$SUBJ/surfanat_brainmask_hires.nii.gz -dxyz 1.0 1.0 2.0 -rmode Cu -orient RAI -inset $DATAROOT/$EXPTDIR/$SUBJ/surfanat_brainmask_master.nii.gz



3dcopy $DATAROOT/$EXPTDIR/$SUBJ/$ANATSUBJ/SUMA/T1.nii $DATAROOT/$EXPTDIR/$SUBJ/anat_T1_brain.nii
