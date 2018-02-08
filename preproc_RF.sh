#!/bin/bash

# preproc_RF.sh
#
# runs full complement of *functional* preprocessing steps required for vistasoft RF-fitting
#
# assumes all anatomical processing finished (recon-all, SUMA directory creation, symlink to fs_subjects)
#
# DIRECTORY STRUCTURE ASSUMED:
# EXPTDIR
# --- SUBJ
# --- ---- SESS1
# --- ---- SESS2
# --- ---- ....
# --- ---- SUBJanat (@SUBJECTS_DIR/SUBJanat/)
#
# EXPTDIR/SUBJ/SESSn should contain files like run*.nii, blip_for/rev*.nii, and
# bias field scans (head_receive_field.nii.gz and body_receive_field.nii.gz)
#
# This script will:
# 1) run bias correction (bias_correct.sh), which will save out _bc.nii.gz files of
#    run, blip nifit's. (this step corrects for strong coil sensitivity profile nearby
#    coil elements, which can interfere with coregistration/alignment)
#   ---> bias_correct.sh
# 2) loop over blip targets ("SEtarg") and unwarp, coregister, align runs nearby
#    in time (specified in the /EXPTDIR/SUBJ/SESS/SUBJ_SESS_SEtargets.txt file)
#    a) unwarp SEtargs, save as SEtarget[n].nii.gz
#    b) use SEtarget[n].nii.gz as external dataset alignment/coregistration targets
#    [we do this because SE images have less dropout, higher CNR than GRE]
#       i) project onto surface and smooth
#    c) relabel runs within .results/ folders to match their run[n] number
#    d) create some very basic alignment QC files (mean run images)
#     (placed in /EXPTDIR/SUBJ/align_QC/SUBJ_SESS_mu_r[n].nii.gz)
#   ---> spatial_afni_proc_SEalign.sh
# 3) convert surface files into volume files for both 'raw' and 'blurred' surface
#    data (will be in EXPTDIR/SUBJ/SESS/SUBJ_SESS.r[#]_surf/ss5.nii.gz)
#   ---> surf_to_vol_SEalign.sh
# 4) generate vista directory with mean timeseries volumes for bias-corrected volume (bc),
#    surface-projected (surf) and surface-smoothed (ss5) data, in RAI orientation
# 5) ensure necessary placeholder images (surfanat_brainmask, etc) are intact


DATAROOT=/deathstar/data

BLURAMT=5   # make this dynamic?  maybe better to keep it static here...

EXPTDIR=$1
SUBJ=$2
SESS=$3


ln -s ../../fs_subjects/${SUBJ}anat $DATAROOT/$EXPTDIR/$SUBJ/${SUBJ}anat


# 1) run bias correction ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PREPROC/bias_correct.sh $EXPTDIR $SUBJ $SESS



# 2 & 3) run spatial unwarping/preprocessing ~~~~~~~~~~~~~~~~~~~~~~~~~

# cores = # of lines in SUBJ_SESS_SEtargets file
CORES=`cat $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}_SEtargets.txt | wc -l`

# make sure we don't blow things up....
export OMP_NUM_THREADS=8

cat $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}_SEtargets.txt | parallel -P $CORES -C ',' \
  $PREPROC/spatial_afni_proc_SEalign.sh $EXPTDIR $SUBJ $SESS {1} {2} {3} $BLURAMT

# reset to default value
export OMP_NUM_THREADS=24


# make QC movie
3dTcat -prefix $DATAROOT/$EXPTDIR/$SUBJ/align_QC/${SUBJ}_${SESS}_mu_all.nii.gz $DATAROOT/$EXPTDIR/$SUBJ/align_QC/${SUBJ}_${SESS}_mu_r*.nii.gz


# put things back into this same volume space...


$PREPROC/surf_to_vol_SEalign.sh $EXPTDIR $SUBJ $SESS surf

# if blurring, do taht too
if [ $BLURAMT != 0 ]
then
  $PREPROC/surf_to_vol_SEalign.sh $EXPTDIR $SUBJ $SESS blur $BLURAMT
fi




$PREPROC/prep_anat.sh $EXPTDIR $SUBJ $SESS


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 4) vista directory
VISTADIR=$DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}_vista
mkdir $VISTADIR

# copy pb02 images, convert to RAI
3dMean -prefix $VISTADIR/bar_seq_1_func.nii.gz $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}*_SEalign.results/pb02*.BRIK*
3dresample -overwrite -prefix $VISTADIR/bar_seq_1_func.nii.gz -orient rai -inset $VISTADIR/bar_seq_1_func.nii.gz

# combine ss5, surf images
3dMean -prefix $VISTADIR/bar_seq_1_surf.nii.gz $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}.r*_surf.nii.gz
3dMean -prefix $VISTADIR/bar_seq_1_ss$BLURAMT.nii.gz $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}.r*_ss$BLURAMT.nii.gz

# QC: motion params, put in align_QC
3dTcat -prefix $DATAROOT/$EXPTDIR/$SUBJ/align_QC/${SUBJ}_${SESS}_motion_all.1D $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}*.results/motion*.1D
