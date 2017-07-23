# RUN RFs!
# (dorf.sh)
# this will launch a quiet matlab window and do all operations necessary to generate RF maps in nii's
# aligned to the freesurfer/SUMA anat at native resolution
#
# will compute a 'raw' version (no smoothing), smooth those maps, then also compute using the surface-smoothed data
#
# for surf-smoothed data, need to use matlab function niftiSqueeze before/after; and need to convert all
# niis to RAI for vista
#
#

# TODO: input args? $1, $2 ,etc

ROOT="/deathstar/data/ssPri_scanner_afni"
SUBJ="KD"
SESS="RF2"

TR=2.5

subjID_vista=${SUBJ}_${SESS}_vista
sessPath=$ROOT/$SUBJ/$SESS/$subjID_vista/

EPIinput="pctDet_surf"   # the 'raw' EPIs we start with (after lots of processing, etc)
EPIext_vista="pctDet_surf_squeeze_RAI" # the ones that go into vista (after some processing, saved w/ this ext)

# for CC RF_eLife
#stimExt="_sameOrder"
stimExt="_sameOrder"


IP="../../surfanat_brainmask_hires.nii.gz"   # needs to be wrt vista directory

N_STIM=3   # 3 bar widths

# go to the vista session directory
cd $sessPath


# (1) convert barwidth nii's to RAI
# (1a) if they're "ss", or if 3dinfo gives 5-d size, run matlab niftiSqueeze

for ((i=1;i<=N_STIM;i++)); do

  echo stim $i:

  #if [ "$(3dinfo -orient bar_width_${i}_${EPIinput}.nii.gz)" != "RAI" ]
  #then
#    echo converting to RAI...#
  #  3dresample -orient RAI -prefix bar_width_${i}_${EPIinput}_RAI.nii.gz -inset bar_width_${i}_${EPIinput}.nii.gz
  #fi

#done

# FLIP THE ORDER OF THESE!!!! nifit-squeeze first, then resmample to RAI. this will fix problems in nii induced by niftiWrite!!!!!!

  if [[ $EPIext==*"ss"* ]] || [[ $EPIext==*"surf"* ]]; then

    echo  nifti-squeezing
    matlab -nosplash -nojvm -nodesktop -r "setup_paths_RFs; nii=niftiRead('bar_width_${i}_${EPIinput}.nii.gz'); nii=niftiSqueeze(nii,${TR}); niftiWrite(nii,'bar_width_${i}_${EPIinput}_squeeze.nii.gz'); exit;"

  fi


  3dresample -orient rai -prefix bar_width_${i}_${EPIext_vista}.nii.gz -inset bar_width_${i}_${EPIinput}_squeeze.nii.gz



done

# testing stuff::::

#idx=1
#var=$(3dinfo -orient bar_width_1_bp.nii.gz)
#if [ "$var" != "RAI" ]
#if [ "$(3dinfo -orient bar_width_${idx}_bp.nii.gz)" != "RAI" ]
#then#
#  echo tommy
#fi




# (2) run do_RFs.m
#
#



# go to the vista session directory
cd $sessPath

matlab -nosplash -nojvm -nodesktop -r "do_RFs('${subjID_vista}', '${sessPath}', '${EPIext_vista}',[],'${stimExt}', ${TR}) ; exit;"



# (3) smooth maps, unless they started smooth; run niiSqueeze





# (4) label all maps? (need to assume param names...)
