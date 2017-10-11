#!/bin/bash

# RF_to_task.sh
#
# project RF mapping data from [surface/functional] space into grid used for task
# - only necessary when the grids used across task/ret differ
#
# runs surf_to_vol_targGrid.sh for surface data, and 3dresample for volume data
# also prepares a set of necessary vista files/directories?
#
# Uses a single 'suffix' to identify these ret runs - something like "_25mm" or "_wmChoose_scanner"
# - this is added to surfanat_brainmask_master and _hires, as well as bar_seq_1_func*/surf*
# - just resamples the existing surfanat_brainmask_master, etc, files
#
# run like:
# $PREPROC/RF_to_task.sh vRF_tcs CC RF1 /deathstar/data/wmChoose_scanner/CC/MGSMap1/func_volreg01.nii.gz _25mm
#
# arguments:
# - RETINOTOPY experiment directory
# - RETINOTOPY SUBJ
# - RETINOTOPY session directory
# - GRIDPARENT nii.gz file (full path)
# - SUFFIX to add to resulting files (include underscore! [or alternate sep char])
#
# NOTE: in principle, GRIDPARENT could be a surfanat file? in such case, don't need to resample existing surfanat in ret dir, just copy?


# ~~~~~~~~ parse args ~~~~~~~~~~~~
DATAROOT=/deathstar/data
EXPTDIR=$1
RETSUBJ=$2
RETSESS=$3
GRIDPARENT=$4
TARGSUFFIX=$5

# ~~~~~~~~ resample surfanat files to GRIDPARENT grid, rename w/ TARGSUFFIX ~~~~~~~~
3dresample -inset  $DATAROOT/$EXPTDIR/$RETSUBJ/surfanat_brainmask_master.nii.gz \
           -prefix $DATAROOT/$EXPTDIR/$RETSUBJ/surfanat_brainmask_master${TARGSUFFIX}.nii.gz \
           -master $GRIDPARENT

# new grid
OLDI=$(3dinfo -adi $GRIDPARENT)
NEWI=$(bc <<< "scale=4; $OLDI/2")
OLDJ=$(3dinfo -adj $GRIDPARENT)
NEWJ=$(bc <<< "scale=4; $OLDJ/2")
NEWK=$(3dinfo -adk $GRIDPARENT)

# make high-res version for vista
3dresample -inset  $DATAROOT/$EXPTDIR/$RETSUBJ/surfanat_brainmask_master${TARGSUFFIX}.nii.gz \
           -prefix $DATAROOT/$EXPTDIR/$RETSUBJ/surfanat_brainmask_hires${TARGSUFFIX}.nii.gz \
           -dxyz $NEWI $NEWJ $NEWK

# ~~~~~~~ run surf_to_vol_targGrid.sh on surf files ~~~~~~~~~~
$PREPROC/surf_to_vol_targGrid.sh $EXPTDIR $RETSUBJ $RETSESS surf 0 $GRIDPARENT $TARGSUFFIX

# clean up (delete lh_*, rh_* files)
rm $DATAROOT/$EXPTDIR/$RETSUBJ/$RETSESS/?h_*.nii.gz



# ~~~~~~~~ same for blur, if interested [TODO] ~~~~~~~~~~~~





# ~~~~~~~ resample func files ~~~~~~~~~~
FUNCPRE="pb02.${RETSUBJ}_${RETSESS}*.r"
FUNCSUF=".volreg+orig.BRIK"
#FUNCSTR="pb02.${SUBJ}_${s}.r*.volreg+orig.BRIK"

## set number of runs for current session

RUN=`ls -l $DATAROOT/$EXPTDIR/$RETSUBJ/$RETSESS/${RETSUBJ}_${RETSESS}*.results/${FUNCPRE}*${FUNCSUF} | wc -l`
rm $DATAROOT/$EXPTDIR/$RETSUBJ/list.txt; for ((i=1;i<=RUN;i++)); do printf "%02.f\n" $i >> $DATAROOT/$EXPTDIR/$RETSUBJ/list.txt; done
CORES=$RUN

# RESMAPLE & COPY BRIK/HEAD to nii/gz in super-directory
cat $DATAROOT/$EXPTDIR/$RETSUBJ/list.txt | parallel -P $CORES \
3dresample -inset  $DATAROOT/$EXPTDIR/$RETSUBJ/$RETSESS/${RETSUBJ}_${RETSESS}*_SEalign.results/${FUNCPRE}{}${FUNCSUF} \
           -prefix $DATAROOT/$EXPTDIR/$RETSUBJ/$RETSESS/${RETSUBJ}_${RETSESS}.r{}_func${TARGSUFFIX}.nii.gz \
           -master $GRIDPARENT -rmode Cu





# ~~~~~~~~ average like runs, put in _vista directory ~~~~~~~~
# surf
3dMean -prefix $DATAROOT/$EXPTDIR/$RETSUBJ/$RETSESS/${RETSUBJ}_${RETSESS}_vista/bar_seq_1_surf${TARGSUFFIX}.nii.gz \
       $DATAROOT/$EXPTDIR/$RETSUBJ/$RETSESS/${RETSUBJ}_${RETSESS}.r*_surf${TARGSUFFIX}.nii.gz

# func
3dMean -prefix $DATAROOT/$EXPTDIR/$RETSUBJ/$RETSESS/${RETSUBJ}_${RETSESS}_vista/bar_seq_1_func${TARGSUFFIX}.nii.gz \
       $DATAROOT/$EXPTDIR/$RETSUBJ/$RETSESS/${RETSUBJ}_${RETSESS}.r*_func${TARGSUFFIX}.nii.gz
