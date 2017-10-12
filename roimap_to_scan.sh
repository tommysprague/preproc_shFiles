# take 1D ROIs (surface) saved somewhere, project them into volume of a given scan
# (typically not necessary; this is mostly for prisma tests)




ROOT=/deathstar/data/wmChoose_scanner


SUBJ=CC
SESS=MGSMap1

AnatSUBJ=${SUBJ}anat


ROILOC=/deathstar/data/vRF_tcs/CC/RF1/CC_RF1_vista/roi

ROIDEST=$ROOT/$SUBJ/rois
mkdir $ROIDEST


TR=1 # null value for nifti squeeze

#GridParent=/deathstar/data/wmChoose_scanner/CC/MGSMap25mm_MB4/CC_MGSMap25mm_MB4_bar_width_1_bc_ss5.nii.gz
GridParent=$ROOT/$SUBJ/surfanat_brainmask_master.nii.gz


cd $ROILOC
cd ..
#cd $ROOT/$SUBJ/$SESS/${SUBJ}_${SESS}_vista

declare -a HEMIS=("lh" "rh")

ROIdir=$ROOT/$SUBJ/$SESS/${SUBJ}_${SESS}_vista/roi

# this generically looks for ROIs on surface and turns them into ROIs on volume

for r in roi/*1D.roi;do

  # ASSUMES: lh.V1.1D.roi, etc

    # extract pertinents
    fname=`echo $r | cut -f 2 -d /`
    hemi=`echo $fname | cut -f 1 -d .`
    area=`echo $fname | cut -f 2 -d .`
    echo $hemi $area

    # surf2vol
    3dSurf2Vol \
    -spec $ROOT/$SUBJ/$AnatSUBJ/SUMA/${AnatSUBJ}_$hemi.spec \
    -surf_A smoothwm \
    -surf_B pial \
    -sv $ROOT/$SUBJ/$AnatSUBJ/SUMA/${AnatSUBJ}_SurfVol+orig. \
    -grid_parent $GridParent \
    -map_func mode \
    -f_steps 15 \
    -sdata_1D $r \
    -sxyz_orient_as_gpar                                  \
    -prefix $ROIDEST/$hemi.${area}.nii.gz \
    -overwrite

# sxyz_orient_as_gpar shoudl give better orientation?
# -tryign out -sdata w/ NIML instead of -sdata1D
  # otherwise, do a _RAI and _squeeze conversion here

  # THIS DOESN'T SEEM NECESSARY? CORRECT NUMBER OF BRIKS?
  # NIFTI SQUEEZE
  #matlab -nosplash -nojvm -nodesktop -r "setup_paths_RFs; nii=niftiRead('$ROIdir/$hemi.${area}.nii.gz'); nii=niftiSqueeze(nii,${TR}); niftiWrite(nii,'$ROIdir/$hemi.${area}.nii.gz'); exit;"

  # RAI
  #3dresample -orient rai -prefix bar_width_${i}_${EPIext_vista}.nii.gz -inset bar_width_${i}_${EPIinput}_squeeze.nii.gz

done

# look for V2v/V2d in each hemisphere and combine them
#for s in "${SESSIONS[@]}"; do
for h in "${HEMIS[@]}"; do
  3dcalc -prefix $ROIDEST/$h.V2.nii.gz -overwrite -a $ROIDEST/$h.V2v.nii.gz -b $ROIDEST/$h.V2d.nii.gz -expr 'or(ispositive(a),ispositive(b))'
  3dcalc -prefix $ROIDEST/$h.V3.nii.gz -overwrite -a $ROIDEST/$h.V3v.nii.gz -b $ROIDEST/$h.V3d.nii.gz -expr 'or(ispositive(a),ispositive(b))'
done



# here, let's look for all LH ROIs (nii.gz's), load the corresponding RH ROI, add them, and save out the "OR"
# [[this just creates bilat ROIs, will not purge overlapping voxels from LH/RH]]

for r in $ROIDEST/lh.*.nii.gz;do

  fname=`echo $r | cut -f 7 -d /`
  #hemi=`echo $fname | cut -f 1 -d .`
  area=`echo $fname | cut -f 2 -d .`
  echo $area

  3dcalc -prefix $ROIDEST/bilat.$area.nii.gz -overwrite -a $ROIDEST/lh.$area.nii.gz -b $ROIDEST/rh.$area.nii.gz -expr 'or(ispositive(a),ispositive(b))'


done


# need to niftisqueeze & convert to RAI
#for r in


# and here, let's go through ROIs in a structured order (how?? using their index?) and purge overlapping voxels
# do this like:
# - first ROI gets all its voxels
# - if second ROI has any overlapping voxels, remove those in ROI1 from ROI2
# - scoot to next pair (V2, V3), if V3 overlaps any w/ V2, remove thsoe vox from V2
# maybe this is biased, but at least seems principled
