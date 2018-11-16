# smooth on the SUMA surface
#
# adapted from surfsmooth.sh, from KD
# TCS, 3/17/2017
#
# assumes you have a subj directory like:
# SUBJ
# - ANATSUBJ
# --- SUMA
# ------ ANATSUBJ_lh/rh.spec
# ------ ANATSUBJ_SurfVol+orig.
# - FUNCsess
# --- $func.nii.gz
#
# Smooths, in surface, by FWHM mm
#
# Proceeds by doing this for LH, RH independently (due to how SUMA handles things),
# then combining these images and saving as a new _ss.nii.gz dataset
#
# ALSO will save out un-smoothed surface-isolated volume images (vol2surf, surf2vol; this will
# restrict voxels in vol to those on surface, and average along surface normals
# between wm and pial surface)
#
# there's now a parallel version of this -  use that if possible, is n_runs x as fast







ANATSUBJ=CC_tcs_combined
FUNCSESS=RF1/CC_RF1_vista
#FUNC=bar_width_1_pct
FWHM=5

declare -a ALLFUNC=("bar_width_1_pct" "bar_width_2_pct" "bar_width_3_pct" "bar_width_1_bp" "bar_width_2_bp" "bar_width_3_bp")

#declare -a ALLFUNC=("wm_nonlinear_all_bp_noDecimate_noC2F-gFit" "wm_nonlinear_all_pct_noDecimate_noC2F-gFit")


for FUNC in "${ALLFUNC[@]}"; do

  # LH
  3dVol2Surf \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./$FUNCSESS/$FUNC.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -oob_value 0 \
  -no_headers \
  -out_niml ./$FUNCSESS/lh_${FUNC}.niml.dset
  #-out_1D ./$FUNCSESS/lh_${FUNC}.1D.dset

  # RH
  3dVol2Surf \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./$FUNCSESS/$FUNC.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -oob_value 0 \
  -no_headers \
  -out_niml ./$FUNCSESS/rh_${FUNC}.niml.dset


  # convert this back into vol (unsmoothed)
  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/$FUNC.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/lh_${FUNC}_surf.nii.gz \
  -sdata ./${FUNCSESS}/lh_${FUNC}.niml.dset


  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/$FUNC.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/rh_${FUNC}_surf.nii.gz \
  -sdata ./${FUNCSESS}/rh_${FUNC}.niml.dset



  #smooth the NIML, then save as vol
  SurfSmooth \
  -met HEAT_07 \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -input ./${FUNCSESS}/lh_${FUNC}.niml.dset \
  -output ./${FUNCSESS}/lh_${FUNC}_ss${FWHM}.niml.dset \
  -target_fwhm $FWHM

  SurfSmooth \
  -met HEAT_07 \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -input ./${FUNCSESS}/rh_${FUNC}.niml.dset \
  -output ./${FUNCSESS}/rh_${FUNC}_ss${FWHM}.niml.dset \
  -target_fwhm $FWHM


  # save smoothed niml as vol
  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/$FUNC.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/lh_${FUNC}_ss${FWHM}.nii.gz \
  -sdata ./${FUNCSESS}/lh_${FUNC}_ss${FWHM}.niml.dset

# NOTE: maybe need to use a BRIK/HEAD as -grid_parent to fix 5-d nii issue?
  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/$FUNC.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/rh_${FUNC}_ss${FWHM}.nii.gz \
  -sdata ./${FUNCSESS}/rh_${FUNC}_ss${FWHM}.niml.dset


  # combine LH/RH - unsmoothed
  # first let's try saving out a mask
  3dcalc -prefix ./${FUNCSESS}/${FUNC}_surf.nii.gz -a ./${FUNCSESS}/lh_${FUNC}_surf.nii.gz -b ./${FUNCSESS}/rh_${FUNC}_surf.nii.gz -expr '(a+b)/(notzero(a)+notzero(b))'

  # combine LH/RH - smoothed
  3dcalc -prefix ./${FUNCSESS}/${FUNC}_ss${FWHM}.nii.gz -a ./${FUNCSESS}/lh_${FUNC}_ss${FWHM}.nii.gz -b ./${FUNCSESS}/rh_${FUNC}_ss${FWHM}.nii.gz -expr '(a+b)/(notzero(a)+notzero(b))'

  # remove intermediate components
  # (lh, rh nii files)
  rm ./${FUNCSESS}/lh*${FUNC}*.nii.gz
  rm ./${FUNCSESS}/rh*${FUNC}*.nii.gz

done
