# misc afni_proc.py commands


# trying out making a spin-echo target for moco/alignment
afni_proc.py -subj_id SEaligntest5 \
             -dsets /deathstar/data/$EXPTDIR/$SUBJ/$SESS/blip_for*_bc.nii.gz \
             -copy_anat /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/brainmask.nii \
             -blocks  volreg \
             -volreg_base_ind 2 0 \
             -volreg_warp_dxyz 2 \
             -blip_forward_dset blip_for2_bc.nii.gz  \
             -blip_reverse_dset blip_rev2_bc.nii.gz
             #-execute


#NOTE: for -volreg_base_ind, the first # (run) should match run # in pb files (1,2,etc; 1-indexed), while the brik # (second arg) should be 0-indexed...


# for surface blurring
afni_proc.py -subj_id ${SUBJ}_${SESS}c \
             -dsets /deathstar/data/$EXPTDIR/$SUBJ/$SESS/run09_bc.nii.gz /deathstar/data/$EXPTDIR/$SUBJ/$SESS/run10_bc.nii.gz /deathstar/data/$EXPTDIR/$SUBJ/$SESS/run11_bc.nii.gz  \
             -copy_anat /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/brainmask.nii \
             -blocks align volreg surf blur \
             -volreg_align_e2a \
             -volreg_base_ind 3 0 \
             -volreg_warp_dxyz 2 \
             -align_opts_aea -cost lpc+ZZ -giant_move \
             -blur_size 5 \
             -surf_anat /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/${SUBJ}anat_fs6b_SurfVol+orig \
             -surf_spec /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/${SUBJ}anat_fs6b_?h.spec \
             -blip_forward_dset blip_for3_bc.nii.gz  \
             -blip_reverse_dset blip_rev3_bc.nii.gz \
             -execute

# TRY: -align_epi_ext_dset

# put surface projection stuff here....
#
# NOTE: afni_proc.py doesn't seem to play well w/ the -NIFTI argument in SUMA_Make_Spec, so using default

align_epi_anat.py -epi2anat                    \
              -anat brainmask.nii                  \
              -epi pb01.MP_RF1.r01.blip+orig        \
              -epi_base 0 -volreg off -tshift off     \
              -giant_move                             \
              -cost lpc -multi_cost lpa lpc+ZZ mi





afni_proc.py -subj_id CC_MGSMap6S \
            -dsets /deathstar/data/PrismaPilotScans/CC/MGSMap6/run*_bc.nii.gz \
            -copy_anat /deathstar/data/PrismaPilotScans/CC/CCanat_fs6b/SUMA/brainmask.nii \
            -blocks align volreg surf blur \
            -volreg_align_e2a \
            -volreg_base_ind 0 503 \
            -blur_size 5 \
            -surf_anat /deathstar/data/PrismaPilotScans/CC/CCanat_fs6b/SUMA/CCanat_fs6b_SurfVol+orig \
            -surf_spec /deathstar/data/PrismaPilotScans/CC/CCanat_fs6b/SUMA/CCanat_fs6b_?h.spec \
            -blip_forward_dset blip_for1_bc.nii.gz  \
            -blip_reverse_dset blip_rev1_bc.nii.gz \
            -execute



# ADD -anat_has_skull no

# for CMRR4, use forward 29, reverse 30
#-blip_forward_dset +29+FMRI_DISTORTION_PA_56sl.nii \
#-blip_reverse_dset +30+FMRI_DISTORTION_AP_56sl.nii

# for CMRR6, use forward 24, reverse 23
#-blip_forward_dset +24+FMRI_DISTORTION_PA_54sl.nii \
#-blip_reverse_dset +23+FMRI_DISTORTION_AP_54sl.nii


# TODO: copy .BRIK/HEAD datasets to a destination directory, rename them appropriately?

#      -blocks align volreg -copy_anat +26+T1_MPRAGE_AP.nii  -blip_forward_dset +29+FMRI_DISTORTION_PA_56sl.nii -blip_reverse_dset +30+FMRI_DISTORTION_AP_56sl.nii -dsets +09+cmrr_mbepi_s4_2mm.nii


#-volreg_align_e2a

# try aligning to first multiband volume, compare to aligning to sbref of first multiband volume (does unwarping still get applied?
# -volreg_align_to first vs
# -volreg_base_dset subj10/vreg_base+orig'[0]'
# looks like the base_dset command does not unwarp the 'external' dset, so we should just use _first for now
#-volreg_base_dset /deathstar/data/PrismaPilotScans/CCpp2_scans/+09+cmrr_mbepi_s4_2mm_sbref.nii \

# for playign w/ bias field stuff:
afni_proc.py -subj_id CC_MGSMap6c \
             -dsets ./run05_bc.nii.gz  \
             -copy_anat /deathstar/data/PrismaPilotScans/CC/CCanat_fs6b/SUMA/brainmask.nii \
             -blocks align volreg \
             -anat_has_skull no \
             -volreg_align_e2a \
             -volreg_base_ind 0 503 \
             -blip_forward_dset blip_for3_bc.nii.gz \
             -blip_reverse_dset blip_rev3_bc.nii.gz \
             -execute

# TYPICALLY: 1 0 (first volume of scan after distortion correction)
# FOR c - need to do last volume before distortion correction (0 335/503)

             #-blur_size 5 \
             #-surf_anat /deathstar/data/PrismaPilotScans/CC/CCanat_fs6b/SUMA/CCanat_fs6b_SurfVol+orig \
             #-surf_spec /deathstar/data/PrismaPilotScans/CC/CCanat_fs6b/SUMA/CCanat_fs6b_?h.spec \
