ROOT=/deathstar/data/vRF_tcs
SUBJ=MSR
SESS=RF1

AnatSUBJ=MSRanat

TR=1 # null value for nifti squeeze

GridParent=bar_seq_1_ss5.nii.gz ##bar_width_1_bc_ss5.nii.gz

cd $ROOT/$SUBJ/$SESS/${SUBJ}_${SESS}_vista

ROIloc=roi_tcs

declare -a HEMIS=("lh" "rh")

ROIdir=$ROOT/$SUBJ/$SESS/${SUBJ}_${SESS}_vista/$ROIloc

# this generically looks for ROIs on surface and turns them into ROIs on volume

for r in $ROIloc/*1D.roi;do

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
    -grid_parent $ROOT/$SUBJ/$SESS/${SUBJ}_${SESS}_vista/$GridParent \
    -map_func mode \
    -f_steps 15 \
    -sdata_1D $r \
    -sxyz_orient_as_gpar                                  \
    -prefix $ROIloc/$hemi.${area}.nii.gz \
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
  3dcalc -prefix $ROIloc/$h.V2.nii.gz -overwrite -a $ROIloc/$h.V2v.nii.gz -b $ROIloc/$h.V2d.nii.gz -expr 'or(ispositive(a),ispositive(b))'
  3dcalc -prefix $ROIloc/$h.V3.nii.gz -overwrite -a $ROIloc/$h.V3v.nii.gz -b $ROIloc/$h.V3d.nii.gz -expr 'or(ispositive(a),ispositive(b))'
done



# here, let's look for all LH ROIs (nii.gz's), load the corresponding RH ROI, add them, and save out the "OR"
# [[this just creates bilat ROIs, will not purge overlapping voxels from LH/RH]]

for r in $ROIloc/lh.*.nii.gz;do

  fname=`echo $r | cut -f 2 -d /`
  #hemi=`echo $fname | cut -f 1 -d .`
  area=`echo $fname | cut -f 2 -d .`
  echo $area

  3dcalc -prefix $ROIloc/bilat.$area.nii.gz -overwrite -a $ROIloc/lh.$area.nii.gz -b $ROIloc/rh.$area.nii.gz -expr 'or(ispositive(a),ispositive(b))'


done


# need to niftisqueeze & convert to RAI
#for r in


# and here, let's go through ROIs in a structured order (how?? using their index?) and purge overlapping voxels
# do this like:
# - first ROI gets all its voxels
# - if second ROI has any overlapping voxels, remove those in ROI1 from ROI2
# - scoot to next pair (V2, V3), if V3 overlaps any w/ V2, remove thsoe vox from V2
# maybe this is biased, but at least seems principled
