ROOT=/deathstar/data/ssPri_scanner_afni
SUBJ=CC
SESS=RF1

AnatSUBJ=CC_tcs_combined

GridParent=bar_width_1_bp_ss5_RAI_squeeze.nii.gz

cd $ROOT/$SUBJ/$SESS/${SUBJ}_${SESS}_vista

for r in roi/*1D.roi;do

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
    -prefix roi/$hemi.${area}.nii.gz
# sxyz_orient_as_gpar shoudl give better orientation?
# -tryign out -sdata w/ NIML instead of -sdata1D
  # otherwise, do a _RAI and _squeeze conversion here
done
