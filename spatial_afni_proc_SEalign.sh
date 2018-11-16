#!/bin/bash

# Run 'spatial' aspects of preprocessing, using afni_proc.py
# - unwarp images for each run
# - motion-correct unwarped data
# - align the alignment target (unwarped SE or GRE AP/PA scans) to the anatomy
# - concatenate all these transformations and apply to get pre-processed volume data
# - project into surface space, then maybe smooth, then project back to volume
#
# BEFORE THIS:
# - anatomical processing (recon-all) must be completed, and SUMA direcotry created
# - functional data (run01...runXX.nii) and field maps (blip_for#/rev#.nii) should be bias-corrected
#   - see bias_correct.sh
# -IMPORTANT: SEtargets (field map pairs used as alignment targets) should be specified
#   - a file in /SUBJ/SESS/ called SUBJ_SESS_SEtargets.txt shoudl contain one line for each SEtargets
#       TARG STARTRUN ENDRUN (with leading 0's)
#
# TODO: add an example file here, with necessary direcotry structures
# TODO: update readme.md to reflect this new procedure...
# TODO: resolution we want to render into?

EXPTDIR=$1

SUBJ=$2
SESS=$3

SEtarg=$4
STARTRUN=$5
ENDRUN=$6


BLURAMT=$7


DATAROOT=/deathstar/data

cd $DATAROOT/$EXPTDIR/$SUBJ/$SESS/


oldthreads=$(echo $OMP_NUM_THREADS)




cd $DATAROOT/$EXPTDIR/$SUBJ/$SESS/
mkdir $DATAROOT/$EXPTDIR/$SUBJ/align_QC

#NOTE: below, if the slice position is such that 'brainmask' ended up recentered relative ot blip images (if blip images are far superior, for example)
#, then SEtarget images will be clipped at superior end (because sampling in brainmask.nii grid). no obvious way to enforce a different grid w/out alignment.
# so we'll align to anat, then align back to pb01 blip images (the first one for convenience)


# use the AP/PA field maps (typically spin-echo images) as targets for moco, alignment (NOTE: in 2.5 mm sequence, these are GRE images)
afni_proc.py -subj_id SEtarget$SEtarg \
             -dsets $DATAROOT/$EXPTDIR/$SUBJ/$SESS/blip_for*_bc.nii.gz \
             -copy_anat $DATAROOT/$EXPTDIR/$SUBJ/${SUBJ}anat/SUMA/brainmask.nii \
             -blocks volreg \
             -volreg_base_ind $SEtarg 0 \
             -anat_has_skull no \
             -blip_forward_dset $DATAROOT/$EXPTDIR/$SUBJ/$SESS/blip_for${SEtarg}_bc.nii.gz  \
             -blip_reverse_dset $DATAROOT/$EXPTDIR/$SUBJ/$SESS/blip_rev${SEtarg}_bc.nii.gz \
             -blip_opts_qw -noXdis -noZdis

# 3dQwarp should use only 1 threads
$PREPROC/substitute_lines.sh proc.SEtarget$SEtarg 1 $oldthreads

# execute script
tcsh -xef proc.SEtarget${SEtarg}_edited 2>&1 | tee output.SEtarget$SEtarg

# for the SE target, average all unwarped volumes
3dTstat -overwrite -mean -prefix SEtarget$SEtarg.nii.gz SEtarget$SEtarg.results/pb01.SEtarget$SEtarg.r$(printf "%02.f" $SEtarg).blip+orig.BRIK


# where do we put results?
RESULTSDIR=${SUBJ}_${SESS}_r${STARTRUN}to${ENDRUN}_SEalign



if [ $BLURAMT = 0 ]
then

# no blurring
afni_proc.py -subj_id $RESULTSDIR \
             -dsets $(printf "/deathstar/data/$EXPTDIR/$SUBJ/$SESS/run%02.f_bc.nii.gz " `seq -s " " $STARTRUN $ENDRUN`) \
             -copy_anat $DATAROOT/$EXPTDIR/$SUBJ/${SUBJ}anat/SUMA/brainmask.nii \
             -blocks align volreg surf \
             -volreg_align_e2a \
             -volreg_base_dset SEtarget$SEtarg.nii.gz \
             -anat_has_skull no \
             -align_opts_aea -cost lpc+ZZ -giant_move \
             -surf_anat $DATAROOT/$EXPTDIR/$SUBJ/${SUBJ}anat/SUMA/${SUBJ}anat_SurfVol+orig \
             -surf_spec $DATAROOT/$EXPTDIR/$SUBJ/${SUBJ}anat/SUMA/${SUBJ}anat_?h.spec \
             -blip_forward_dset blip_for${SEtarg}_bc.nii.gz  \
             -blip_reverse_dset blip_rev${SEtarg}_bc.nii.gz \
             -blip_opts_qw -noXdis -noZdis

  # 3dQwarp should use only 1 threads
  $PREPROC/substitute_lines.sh proc.$RESULTSDIR 1 $oldthreads

  # execute script
  tcsh -xef proc.${RESULTSDIR}_edited 2>&1 | tee output.$RESULTSDIR




else

  afni_proc.py -subj_id $RESULTSDIR \
               -dsets $(printf "/deathstar/data/$EXPTDIR/$SUBJ/$SESS/run%02.f_bc.nii.gz " `seq -s " " $STARTRUN $ENDRUN`) \
               -copy_anat $DATAROOT/$EXPTDIR/$SUBJ/${SUBJ}anat/SUMA/brainmask.nii \
               -blocks align volreg surf blur \
               -volreg_align_e2a \
               -volreg_base_dset SEtarget$SEtarg.nii.gz \
               -anat_has_skull no \
               -align_opts_aea -cost lpc+ZZ -giant_move \
               -surf_anat $DATAROOT/$EXPTDIR/$SUBJ/${SUBJ}anat/SUMA/${SUBJ}anat_SurfVol+orig \
               -surf_spec $DATAROOT/$EXPTDIR/$SUBJ/${SUBJ}anat/SUMA/${SUBJ}anat_?h.spec \
               -blur_size $BLURAMT \
               -blip_forward_dset blip_for${SEtarg}_bc.nii.gz  \
               -blip_reverse_dset blip_rev${SEtarg}_bc.nii.gz \
               -blip_opts_qw -noXdis -noZdis

  # 3dQwarp should use only 1 threads
  $PREPROC/substitute_lines.sh proc.$RESULTSDIR 1 $oldthreads

  # execute script
  tcsh -xef proc.${RESULTSDIR}_edited 2>&1 | tee output.$RESULTSDIR



fi


# must make STARTRUN; ENDRUN base10...$((10#$STARTRUN))

# loop from end to beginning of run list, converting all r## (1-n) to startrun:endrun
runidx=$(( $((10#$ENDRUN)) - $((10#$STARTRUN)) + 1 ))
for (( i=$((10#$ENDRUN)); i>=$((10#$STARTRUN)); i-- ))
do
  echo Renaming run $runidx to run $i

# perl rename str   # rename -n -v 's/\.r02.(.*.)\./.r03.$1./' *.suff
  repstr=s/`printf "\.r%02.f.(.*.)\." $runidx`/`printf ".r%02.f." $i`'$1'./
  rename -v $repstr `printf "$RESULTSDIR.results/*.r%02.f.*" $runidx`

  runidx=$(( $runidx - 1 ))
done


# make QC files ($SUBJ/align_QC/$SUBJ_$SESS_mu_r$i.nii.gz)

# average over each run
for ii in $(seq -s " " $STARTRUN $ENDRUN)
do
  rnum=$(printf "%02.f" $ii)
  3dTstat -mean -prefix ../align_QC/${SUBJ}_${SESS}_mu_r$rnum.nii.gz $RESULTSDIR.results/pb02.$RESULTSDIR.r$rnum.volreg+orig
done
