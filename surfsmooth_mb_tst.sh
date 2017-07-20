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
#
# At conclusion of vol --> surf --> vol transforms, resulting nii.gz's are poorly built - they're
# missing info about # TRs and they're written to 5D
# - loops through runs within session and 'squeezes' the nifti using preproc_mFiles toolbox niftiSqueeze
# - looks up TR from the $FUNCSESS and uses that to reset TR value in nifti
# - transforms data to RAI, which is the final space we want *all* data in

# REMEMBER: need to copy a volreg scan as well as the 'gridparent'




ROOT=/deathstar/data/PrismaPilotScans
SUBJ=CC
ANATSUBJ=CCanat_fs6b
FUNCSESS=MGSMap4
#FUNCSESS=RF1
#FUNC=bar_width_1_pct
FWHM=5
CORES=4

TR=0.8   # TODO: figure out how to get this dynamically per run (hard w/ parallel command...)

# TODO: loop over funcsess (also, loop over _ss5/_surf files as sensically as possible...)


#declare -a ALLFUNC=("bar_width_1_pct" "bar_width_2_pct" "bar_width_3_pct" "bar_width_1_bp" "bar_width_2_bp" "bar_width_3_bp")
#declare -a ALLFUNC=("bar_width_1_pctDet" "bar_width_2_pctDet" "bar_width_3_pctDet")
#declare -a ALLFUNC=("bar_width_1_pctDet" "bar_width_2_pctDet" "bar_width_3_pctDet")


PREPROC_DIR="/deathstar/data/PrismaPilotScans/CCpp2_scans/bias_field/CCpp2_CMRR4_unwarp_bc.results/"


#FUNCPREFIX="func_normPctDet*"
FUNCPREFIX_lh="pb03.CCpp2_CMRR6_unwarp_bc.lh.r*.surf.niml.dset"
FUNCPREFIX_rh="pb03.CCpp2_CMRR6_unwarp_bc.rh.r*.surf.niml.dset"
FUNCPREFIX="CCpp2_CMRR6_unwarp_bc" #"pb04.CCpp2_CMRR4_unwarp_ss.lh.r03.blur.niml.dset"
#FUNCPREFIX="bar_width_*pctDet*"


# copy things to subj directory
#cp ${PREPROC_DIR}$FUNCPREFIX_lh $ROOT/$SUBJ/$FUNCSESS/
#cp ${PREPROC_DIR}$FUNCPREFIX_rh $ROOT/$SUBJ/$FUNCSESS/



#declare -a ALLFUNC=("wm_nonlinear_all_bp_noDecimate_noC2F-gFit" "wm_nonlinear_all_pct_noDecimate_noC2F-gFit")
#rm ./func_list.txt; for FUNC in "${ALLFUNC[@]}"; do printf "%s\n" $FUNC >> ./func_list.txt; done

cd $ROOT/$SUBJ/$FUNCSESS
#$fname | cut -f 1 -d .`

# IF DOING TASK:::::
rm ./func_list_lh.txt; for FUNC in $FUNCPREFIX_lh; do printf "%s\n" $FUNC | cut -f -4 -d . >> ./func_list_lh.txt; done
rm ./func_list_rh.txt; for FUNC in $FUNCPREFIX_rh; do printf "%s\n" $FUNC | cut -f -4 -d . >> ./func_list_rh.txt; done

# list of output filenames
rm ./func_list.txt; for FUNC in $FUNCPREFIX_lh; do printf "%s.%s\n" $FUNC | cut -f 2,4 -d .   >> ./func_list.txt; done

# list of runs
rm ./run_list.txt; for FUNC in $FUNCPREFIX_lh; do printf "%s.%s\n" $FUNC | cut -f 4 -d .   >> ./run_list.txt; done


# IF DOING RFs:
#rm ./func_list.txt; for FUNC in $ALLFUNC; do printf "%s\n" $FUNC.nii.gz | cut -f 1 -d . >> ./func_list.txt; done





cd $ROOT/$SUBJ

#for FUNC in "${ALLFUNC[@]}"; do

# this is how we did parallel in spatial:
#cat ./list.txt | parallel -P $CORES \
#3dcopy $s/run{}/func{}_to_T1+orig. $s/reg_func{}_to_T1.nii.gz


# note: removing nii.gz below, expects filenames to have extensions

  # LH
##### TEST THIS STILLL!!!!!!!!!!!
# cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
# 3dVol2Surf \
#   -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
#   -surf_A smoothwm \
#   -surf_B pial \
#   -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
#   -grid_parent ./$FUNCSESS/{}.nii.gz \
#   -map_func ave \
#   -f_steps 10 \
#   -oob_value 0 \
#   -no_headers \
#   -out_niml ./$FUNCSESS/lh_{}.niml.dset
#   #-out_1D ./$FUNCSESS/lh_${FUNC}.1D.dset
#
#   # RH
#   cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
#   3dVol2Surf \
#   -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
#   -surf_A smoothwm \
#   -surf_B pial \
#   -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
#   -grid_parent ./$FUNCSESS/{}.nii.gz \
#   -map_func ave \
#   -f_steps 10 \
#   -oob_value 0 \
#   -no_headers \
#   -out_niml ./$FUNCSESS/rh_{}.niml.dset


  # convert this back into vol (unsmoothed)
  cat ./$FUNCSESS/func_list_lh.txt | parallel -P $CORES \
  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/${FUNCPREFIX}_r01.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/{}_surf.nii.gz \
  -sdata ./${FUNCSESS}/{}.surf.niml.dset

  cat ./$FUNCSESS/func_list_rh.txt | parallel -P $CORES \
  3dSurf2Vol \
  -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
  -surf_A smoothwm \
  -surf_B pial \
  -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
  -grid_parent ./${FUNCSESS}/${FUNCPREFIX}_r01.nii.gz \
  -map_func ave \
  -f_steps 10 \
  -prefix ./${FUNCSESS}/{}_surf.nii.gz \
  -sdata ./${FUNCSESS}/{}.surf.niml.dset

# NOTE: above, swithc "surf" to ss5/blur



  #smooth the NIML, then save as vol
#   cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
#   SurfSmooth \
#   -met HEAT_07 \
#   -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
#   -surf_A smoothwm \
#   -surf_B pial \
#   -input ./${FUNCSESS}/lh_{}.niml.dset \
#   -output ./${FUNCSESS}/lh_{}_ss${FWHM}.niml.dset \
#   -target_fwhm $FWHM
#
#   cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
#   SurfSmooth \
#   -met HEAT_07 \
#   -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
#   -surf_A smoothwm \
#   -surf_B pial \
#   -input ./${FUNCSESS}/rh_{}.niml.dset \
#   -output ./${FUNCSESS}/rh_{}_ss${FWHM}.niml.dset \
#   -target_fwhm $FWHM
#
#
#   # save smoothed niml as vol
#   cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
#   3dSurf2Vol \
#   -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_lh.spec \
#   -surf_A smoothwm \
#   -surf_B pial \
#   -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
#   -grid_parent ./${FUNCSESS}/{}.nii.gz \
#   -map_func ave \
#   -f_steps 10 \
#   -prefix ./${FUNCSESS}/lh_{}_ss${FWHM}.nii.gz \
#   -sdata ./${FUNCSESS}/lh_{}_ss${FWHM}.niml.dset
#
# # NOTE: maybe need to use a BRIK/HEAD as -grid_parent to fix 5-d nii issue?
#   cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
#   3dSurf2Vol \
#   -spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
#   -surf_A smoothwm \
#   -surf_B pial \
#   -sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
#   -grid_parent ./${FUNCSESS}/{}.nii.gz \
#   -map_func ave \
#   -f_steps 10 \
#   -prefix ./${FUNCSESS}/rh_{}_ss${FWHM}.nii.gz \
#   -sdata ./${FUNCSESS}/rh_{}_ss${FWHM}.niml.dset


  # combine LH/RH - unsmoothed
  # first let's try saving out a mask


# RENAME THEM TO SOMETHING SENSICAL
cat ./$FUNCSESS/run_list.txt | parallel -P $CORES \
mv ./$FUNCSESS/pb03.$FUNCPREFIX.rh.{}_surf.nii.gz ./$FUNCSESS/rh_${FUNCPREFIX}.{}_surf.nii.gz

cat ./$FUNCSESS/run_list.txt | parallel -P $CORES \
mv ./$FUNCSESS/pb03.$FUNCPREFIX.lh.{}_surf.nii.gz ./$FUNCSESS/lh_${FUNCPREFIX}.{}_surf.nii.gz


  cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  3dcalc -prefix ./${FUNCSESS}/{}_surf.nii.gz -a ./${FUNCSESS}/lh_{}_surf.nii.gz -b ./${FUNCSESS}/rh_{}_surf.nii.gz -expr "'(a+b)/(notzero(a)+notzero(b))'"

cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
echo {}

  # # combine LH/RH - smoothed
  # cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  # 3dcalc -prefix ./${FUNCSESS}/{}_ss${FWHM}.nii.gz -a ./${FUNCSESS}/lh_{}_ss${FWHM}.nii.gz -b ./${FUNCSESS}/rh_{}_ss${FWHM}.nii.gz -expr "'(a+b)/(notzero(a)+notzero(b))'"

  # remove intermediate components
  # (lh, rh nii files)
  # cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  # rm ./${FUNCSESS}/lh*{}*.nii.gz
  #
  # cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  # rm ./${FUNCSESS}/rh*{}*.nii.gz
  #
  # # (lh, rh nii files)
  # cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  # rm ./${FUNCSESS}/lh*{}*.dset
  #
  # cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  # rm ./${FUNCSESS}/rh*{}*.dset
  #
  # # (lh, rh nii files)
  # cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  # rm ./${FUNCSESS}/lh*{}*.smrec
  #
  # cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  # rm ./${FUNCSESS}/rh*{}*.smrec



  # squeeze & reset TR [[_surf]]
  for FUNC in $(cat ./$FUNCSESS/func_list.txt);
  do
    #matlab -nosplash -nojvm -nodesktop -r "setup_paths_RFs; nii=niftiRead('./${FUNCSESS}/${FUNC}_surf.nii.gz'); nii=niftiSqueeze(nii,$(3dinfo -tr ./${FUNCSESS}/${FUNC}.nii.gz)); niftiWrite(nii,'./${FUNCSESS}/${FUNC}_surf.nii.gz'); exit;";
    matlab -nosplash -nojvm -nodesktop -r "setup_paths_RFs; nii=niftiRead('./${FUNCSESS}/${FUNC}_surf.nii.gz'); nii=niftiSqueeze(nii,${TR}); niftiWrite(nii,'./${FUNCSESS}/${FUNC}_surf.nii.gz'); exit;";
  done


  # #squeeze & reset TR [[_ss5]] TODO: if do_smoothing
  # for FUNC in $(cat ./$FUNCSESS/func_list.txt);
  # do
  #   matlab -nosplash -nojvm -nodesktop -r "setup_paths_RFs; nii=niftiRead('./${FUNCSESS}/${FUNC}_ss5.nii.gz'); nii=niftiSqueeze(nii,$(3dinfo -tr ./${FUNCSESS}/${FUNC}.nii.gz) ); niftiWrite(nii,'./${FUNCSESS}/${FUNC}_ss5.nii.gz'); exit;";
  # done


  # finally, put them in RAI (preferred by vista; all ROIs in this orientation)
  cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  3dresample -overwrite -prefix ./${FUNCSESS}/{}_surf.nii.gz -orient rai -inset ./${FUNCSESS}/{}_surf.nii.gz

  # # finally, put them in RAI (preferred by vista; all ROIs in this orientation)
  # cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
  # 3dresample -overwrite -prefix ./${FUNCSESS}/{}_ss5.nii.gz -orient rai -inset ./${FUNCSESS}/{}_ss5.nii.gz
