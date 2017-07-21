# bias_correct.sh

cd /deathstar/data/vRF_tcs/MP/RF1/

FUNCPREFIX=run
BLIPPREFIX=blip_
CORES=12

# mask, then add 1 where bias field == 0 (because we divide by this)
3dAutomask -prefix head_mask.nii.gz -clfrac 0.3 -overwrite head_receive_field.nii.gz



# first compute bias field (head/body)
3dcalc -a head_receive_field.nii.gz -b body_receive_field.nii.gz -c head_mask.nii.gz -prefix bias_field_masked.nii.gz -expr '((a*c)/(b*c))'


# then blur by some FWHM (10?)
3dBlurToFWHM -input bias_field_masked.nii.gz -prefix bias_field_blur15.nii.gz -FWHM 15 -mask head_mask.nii.gz -overwrite

# then 'align' to bounding box of first EPI (shouldn't actually need to align, but need to resample to this box)
# TODO: have to do this for each scan we want to bias-correct (w/ different RX)
# shfitonly? [TODO: need to do this to nearest functional scan, not just first run of this seq]
3dAllineate -1Dmatrix_save bias2func.1D -source body_receive_field.nii.gz -base run01.nii[0] -master BASE -prefix head_receive_field_al.nii.gz

# apply that transform also to the bias field itself
3dAllineate -1Dmatrix_apply bias2func.1D -source bias_field_blur15.nii.gz -base run01.nii[0] -master BASE -prefix bias_al.nii.gz -overwrite
3dAllineate -1Dmatrix_apply bias2func.1D -source head_mask.nii.gz -base run01.nii[0] -master BASE -prefix mask_al.nii.gz -overwrite


rm ./bc_func_list.txt; for FUNC in ${FUNCPREFIX}*.nii; do printf "%s\n" $FUNC | cut -f -1 -d . >> ./bc_func_list.txt; done
rm ./bc_blip_list.txt; for BLIP in ${BLIPPREFIX}*.nii; do printf "%s\n" $BLIP | cut -f -1 -d . >> ./bc_blip_list.txt; done



# then apply to the scan(s) we want
cat ./bc_func_list.txt | parallel -P $CORES \
3dcalc -a {}.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix {}_bc.nii.gz -expr "'c*(a/b)'"# -overwrite

cat ./bc_blip_list.txt | parallel -P $CORES \
3dcalc -a {}.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix {}_bc.nii.gz -expr "'c*(a/b)'"# -overwrite


# 3dcalc -a run01.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run01_bc.nii.gz -expr 'c*(a/b)' -overwrite
# 3dcalc -a run02.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run02_bc.nii.gz -expr 'c*(a/b)' -overwrite
# 3dcalc -a run03.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run03_bc.nii.gz -expr 'c*(a/b)' -overwrite
# 3dcalc -a run04.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run04_bc.nii.gz -expr 'c*(a/b)' -overwrite
# 3dcalc -a run05.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run05_bc.nii.gz -expr 'c*(a/b)' -overwrite
# 3dcalc -a run06.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run06_bc.nii.gz -expr 'c*(a/b)' -overwrite
# 3dcalc -a run07.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run07_bc.nii.gz -expr 'c*(a/b)' -overwrite
# #3dcalc -a run08.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run08_bc.nii.gz -expr 'c*(a/b)' -overwrite
# #3dcalc -a run09.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run09_bc.nii.gz -expr 'c*(a/b)' -overwrite
# #3dcalc -a run10.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix run10_bc.nii.gz -expr 'c*(a/b)' -overwrite
#
#
#
#
# 3dcalc -a blip_for1.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix blip_for1_bc.nii.gz -expr 'c*(a/b)' -overwrite
# 3dcalc -a blip_rev1.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix blip_rev1_bc.nii.gz -expr 'c*(a/b)' -overwrite
#
# 3dcalc -a blip_for2.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix blip_for2_bc.nii.gz -expr 'c*(a/b)' -overwrite
# 3dcalc -a blip_rev2.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix blip_rev2_bc.nii.gz -expr 'c*(a/b)' -overwrite
#
# #3dcalc -a blip_for3.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix blip_for3_bc.nii.gz -expr 'c*(a/b)' -overwrite
# #3dcalc -a blip_rev3.nii -b bias_al.nii.gz -c mask_al.nii.gz -prefix blip_rev3_bc.nii.gz -expr 'c*(a/b)' -overwrite
#
#
# # TODO: need to mask this somehow? divide by masked bias field + 1?
# # TODO tomorrow - rename blips w/ s6, s4; get a s4 bias corrected dataset ready
