#!/bin/bash

# preproc_task.sh
#
# runs full complement of *functional* preprocessing steps for multivariate task-based analyses
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
# 4) perform temporal processing on 'raw' (temporal_task_mb.sh) and surface data (temporal_task_surf.sh)
#    [mostly, turn to percent signal change]


DATAROOT=/deathstar/data

BLURAMT=0   # make this dynamic?  maybe better to keep it static here...

EXPTDIR=$1
SUBJ=$2
SESS=$3


ln -s ../../fs_subjects/${SUBJ}anat $DATAROOT/$EXPTDIR/$SUBJ/${SUBJ}anat




# 1) run bias correction
$PREPROC/bias_correct.sh $EXPTDIR $SUBJ $SESS



# 2 & 3) run spatial unwarping/preprocessing
#$PREPROC/spatial_afni_proc_SEalign.sh $EXPTDIR $SUBJ $SESS $BLURAMT

cd $DATAROOT/$EXPTDIR/$SUBJ/$SESS/


# cores = # of lines in SUBJ_SESS_SEtargets file
CORES=`cat $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}_SEtargets.txt | wc -l`

# make sure we don't blow things up....
export OMP_NUM_THREADS=8 

cat $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}_SEtargets.txt | parallel -P $CORES -C ',' \
  $PREPROC/spatial_afni_proc_SEalign.sh $EXPTDIR $SUBJ $SESS {1} {2} {3} $BLURAMT

# reset to default value
export OMP_NUM_THREADS=24


# QC: motion params, put in align_QC
cat $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}*.results/motion*.1D >  $DATAROOT/$EXPTDIR/$SUBJ/align_QC/${SUBJ}_${SESS}_motion_all.1D

# make QC movie
3dTcat -prefix $DATAROOT/$EXPTDIR/$SUBJ/align_QC/${SUBJ}_${SESS}_mu_all.nii.gz $DATAROOT/$EXPTDIR/$SUBJ/align_QC/${SUBJ}_${SESS}_mu_r*.nii.gz


# put things back into this same volume space...
$PREPROC/surf_to_vol_SEalign.sh $EXPTDIR $SUBJ $SESS surf


# create masks, etc, needed for temporal processing
$PREPROC/prep_anat.sh $EXPTDIR $SUBJ $SESS

# 4) do temporal preprocessing on 'func' data (full volumes; pb02 files)

# a) move pb02 files into here as func_volreg [took this from temporal_task*.sh]
FUNCPRE="pb02.${SUBJ}_${SESS}*.r"
FUNCSUF=".volreg+orig.BRIK*"
#FUNCSTR="pb02.${SUBJ}_${s}.r*.volreg+orig.BRIK"

## set number of runs for current session
RUN=`ls -l $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}*.results/${FUNCPRE}*${FUNCSUF} | wc -l`
rm $DATAROOT/$EXPTDIR/$SUBJ/list.txt; for ((i=1;i<=RUN;i++)); do printf "%02.f\n" $i >> $DATAROOT/$EXPTDIR/$SUBJ/list.txt; done
CORES=$RUN

# COPY BRIK/HEAD to nii/gz in super-directory
cat $DATAROOT/$EXPTDIR/$SUBJ/list.txt | parallel -P $CORES \
3dcopy $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}*_SEalign.results/${FUNCPRE}{}${FUNCSUF} $DATAROOT/$EXPTDIR/$SUBJ/$SESS/func{}_volreg.nii.gz

# run the temporal processing
$PREPROC/temporal_task.sh $EXPTDIR $SUBJ $SESS func

# and the surf data
FUNCPRE="${SUBJ}_${SESS}.r"
FUNCSUF="_surf.nii.gz"

## set number of runs for current session
RUN=`ls -l $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${FUNCPRE}*${FUNCSUF} | wc -l`
rm $DATAROOT/$EXPTDIR/$SUBJ/list.txt; for ((i=1;i<=RUN;i++)); do printf "%02.f\n" $i >> $DATAROOT/$EXPTDIR/$SUBJ/list.txt; done
CORES=$RUN


# COPY BRIK/HEAD to nii/gz in super-directory
cat $DATAROOT/$EXPTDIR/$SUBJ/list.txt | parallel -P $CORES \
mv $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${FUNCPRE}{}${FUNCSUF} $DATAROOT/$EXPTDIR/$SUBJ/$SESS/surf{}_volreg.nii.gz

# run the temporal preprocessing for surf files# run the temporal processing
$PREPROC/temporal_task.sh $EXPTDIR $SUBJ $SESS surf
