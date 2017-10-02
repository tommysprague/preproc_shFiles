#!/bin/bash
# bias_correct.sh

DATAROOT=/deathstar/data
EXPTDIR=$1
SUBJ=$2
SESS=$3

cd $DATAROOT/$EXPTDIR/$SUBJ/$SESS

FUNCPREFIX=run
BLIPPREFIX=blip_

# mask, then add 1 where bias field == 0 (because we divide by this)
3dAutomask -prefix head_mask.nii.gz -clfrac 0.3 -overwrite head_receive_field.nii.gz

# first compute bias field (head/body)
3dcalc -a head_receive_field.nii.gz -b body_receive_field.nii.gz -c head_mask.nii.gz -prefix bias_field_masked.nii.gz -expr '((a*c)/(b*c))'

# then blur by some FWHM (10?)
3dBlurToFWHM -input bias_field_masked.nii.gz -prefix bias_field_blur15.nii.gz -FWHM 15 -mask head_mask.nii.gz -overwrite

# then 'align' to bounding box of first EPI (shouldn't actually need to align, but need to resample to this box)
3dAllineate -1Dmatrix_save bias2func.1D -source body_receive_field.nii.gz -base run01.nii*[0] -master BASE -prefix body_receive_field_al.nii.gz

# apply that transform also to the bias field itself
3dAllineate -1Dmatrix_apply bias2func.1D -source bias_field_blur15.nii.gz -base run01.nii*[0] -master BASE -prefix bias_al.nii.gz -overwrite
3dAllineate -1Dmatrix_apply bias2func.1D -source head_mask.nii.gz -base run01.nii*[0] -master BASE -prefix mask_al.nii.gz -overwrite

rm ./bc_func_list.txt; for FUNC in ${FUNCPREFIX}*.nii*; do printf "%s\n" $FUNC | cut -f -1 -d . >> ./bc_func_list.txt; done
rm ./bc_blip_list.txt; for BLIP in ${BLIPPREFIX}*.nii*; do printf "%s\n" $BLIP | cut -f -1 -d . >> ./bc_blip_list.txt; done


CORES=$(cat ./bc_func_list.txt | wc -l)

# then apply to the scan(s) we want
cat ./bc_func_list.txt | parallel -P $CORES \
3dcalc -a {}.nii* -b bias_al.nii.gz -c mask_al.nii.gz -prefix {}_bc.nii.gz -expr "'c*(a/b)'" -overwrite

CORES=$(cat ./bc_blip_list.txt | wc -l)
cat ./bc_blip_list.txt | parallel -P $CORES \
3dcalc -a {}.nii* -b bias_al.nii.gz -c mask_al.nii.gz -prefix {}_bc.nii.gz -expr "'c*(a/b)'" -overwrite
