# smooth on the SUMA surface
#
# adapted from surfsmooth.sh, from KD
# adapted from surfsmooth_tcs.sh, from TCS
# TCS, 4/10/2017
#
# attempts to do parallel processing (this step is *very* slow)
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
# meant to be run from subj ROOT directory







ANATSUBJ=MRanat
FUNCSESS=RF1/MR_RF1_vista
#FUNC=bar_width_1_pct
FWHM=5
CORES=6

declare -a ALLFUNC=("bar_width_1_pct" "bar_width_2_pct" "bar_width_3_pct" "bar_width_1_bp" "bar_width_2_bp" "bar_width_3_bp")

#declare -a ALLFUNC=("wm_nonlinear_all_bp_noDecimate_noC2F-gFit" "wm_nonlinear_all_pct_noDecimate_noC2F-gFit")
rm ./func_list.txt; for FUNC in "${ALLFUNC[@]}"; do printf "%s\n" $FUNC >> ./func_list.txt; done

#for FUNC in "${ALLFUNC[@]}"; do

# this is how we did parallel in spatial:
#cat ./list.txt | parallel -P $CORES \
#3dcopy $s/run{}/func{}_to_T1+orig. $s/reg_func{}_to_T1.nii.gz




  # LH
##### TEST THIS STILLL!!!!!!!!!!!
cat ./func_list.txt | parallel -P $CORES \
3dVol2Surf \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./$FUNCSESS/{}.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -oob_value 0 \
  -no_headers \
  -out_niml ./$FUNCSESS/lh_{}.niml.dset
  #-out_1D ./$FUNCSESS/lh_${FUNC}.1D.dset

  # RH
  cat ./func_list.txt | parallel -P $CORES \
  3dVol2Surf \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./$FUNCSESS/{}.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -oob_value 0 \
  -no_headers \
  -out_niml ./$FUNCSESS/rh_{}.niml.dset


  # convert this back into vol (unsmoothed)
  cat ./func_list.txt | parallel -P $CORES \
  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/{}.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/lh_{}_surf.nii.gz \
  -sdata ./${FUNCSESS}/lh_{}.niml.dset

  cat ./func_list.txt | parallel -P $CORES \
  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/{}.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/rh_{}_surf.nii.gz \
  -sdata ./${FUNCSESS}/rh_{}.niml.dset



  #smooth the NIML, then save as vol
  cat ./func_list.txt | parallel -P $CORES \
  SurfSmooth \
  -met HEAT_07 \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -input ./${FUNCSESS}/lh_{}.niml.dset \
  -output ./${FUNCSESS}/lh_{}_ss${FWHM}.niml.dset \
  -target_fwhm $FWHM

  cat ./func_list.txt | parallel -P $CORES \
  SurfSmooth \
  -met HEAT_07 \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -input ./${FUNCSESS}/rh_{}.niml.dset \
  -output ./${FUNCSESS}/rh_{}_ss${FWHM}.niml.dset \
  -target_fwhm $FWHM


  # save smoothed niml as vol
  cat ./func_list.txt | parallel -P $CORES \
  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/{}.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/lh_{}_ss${FWHM}.nii.gz \
  -sdata ./${FUNCSESS}/lh_{}_ss${FWHM}.niml.dset

# NOTE: maybe need to use a BRIK/HEAD as -grid_parent to fix 5-d nii issue?
  cat ./func_list.txt | parallel -P $CORES \
  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/{}.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/rh_{}_ss${FWHM}.nii.gz \
  -sdata ./${FUNCSESS}/rh_{}_ss${FWHM}.niml.dset


  # combine LH/RH - unsmoothed
  # first let's try saving out a mask
  cat ./func_list.txt | parallel -P $CORES \
  3dcalc -prefix ./${FUNCSESS}/{}_surf.nii.gz -a ./${FUNCSESS}/lh_{}_surf.nii.gz -b ./${FUNCSESS}/rh_{}_surf.nii.gz -expr "'(a+b)/(notzero(a)+notzero(b))'"

  # combine LH/RH - smoothed
  cat ./func_list.txt | parallel -P $CORES \
  3dcalc -prefix ./${FUNCSESS}/{}_ss${FWHM}.nii.gz -a ./${FUNCSESS}/lh_{}_ss${FWHM}.nii.gz -b ./${FUNCSESS}/rh_{}_ss${FWHM}.nii.gz -expr "'(a+b)/(notzero(a)+notzero(b))'"

  # remove intermediate components
  # (lh, rh nii files)
  cat ./func_list.txt | parallel -P $CORES \
  rm ./${FUNCSESS}/lh*{}*.nii.gz

  cat ./func_list.txt | parallel -P $CORES \
  rm ./${FUNCSESS}/rh*{}*.nii.gz

  # (lh, rh nii files)
  cat ./func_list.txt | parallel -P $CORES \
  rm ./${FUNCSESS}/lh*{}*.dset

  cat ./func_list.txt | parallel -P $CORES \
  rm ./${FUNCSESS}/rh*{}*.dset

  # (lh, rh nii files)
  cat ./func_list.txt | parallel -P $CORES \
  rm ./${FUNCSESS}/lh*{}*.smrec

  cat ./func_list.txt | parallel -P $CORES \
  rm ./${FUNCSESS}/rh*{}*.smrec


#done
