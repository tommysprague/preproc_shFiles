subject=KDs2_fs6
func=normpct_prepost
fwhm=5


3dVol2Surf \
-spec SUMA/${subject}_lh.spec \
-surf_A smoothwm \
-surf_B pial \
-sv brain_Alnd_Exp+orig. \
-grid_parent $func.nii.gz \
-map_func ave \
-f_steps 10 \
-oob_value 0 \
-no_headers \
-out_1D lh_${func}.1D.dset

3dVol2Surf \
-spec SUMA/${subject}_rh.spec \
-surf_A smoothwm \
-surf_B pial \
-sv brain_Alnd_Exp+orig. \
-grid_parent $func.nii.gz \
-map_func ave \
-f_steps 10 \
-oob_value 0 \
-no_headers \
-out_1D rh_${func}.1D.dset


SurfSmooth \
-met HEAT_07 \
-spec SUMA/${subject}_lh.spec \
-surf_A smoothwm \
-surf_B pial \
-input lh_${func}.1D.dset \
-output lh_${func}_ss${fwhm}.1D.dset \
-target_fwhm $fwhm

SurfSmooth \
-met HEAT_07 \
-spec SUMA/${subject}_rh.spec \
-surf_A smoothwm \
-surf_B pial \
-input rh_${func}.1D.dset \
-output rh_${func}_ss${fwhm}.1D.dset \
-target_fwhm $fwhm


3dSurf2Vol \
-spec SUMA/${subject}_lh.spec \
-surf_A smoothwm \
-surf_B pial \
-sv brain_Alnd_Exp+orig. \
-grid_parent $func.nii.gz \
-map_func ave \
-f_steps 10 \
-prefix lh_${func}_ss${fwhm}.nii.gz \
-sdata lh_${func}.1D.dset

3dSurf2Vol \
-spec SUMA/${subject}_rh.spec \
-surf_A smoothwm \
-surf_B pial \
-sv brain_Alnd_Exp+orig. \
-grid_parent $func.nii.gz \
-map_func ave \
-f_steps 10 \
-prefix rh_${func}_ss${fwhm}.nii.gz \
-sdata rh_${func}.1D.dset

