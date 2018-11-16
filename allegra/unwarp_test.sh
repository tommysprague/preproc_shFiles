afni_proc.py -subj_id CCpp2_CMRR4_SBREF_unwarp \
             -dsets /deathstar/data/PrismaPilotScans/CCpp2_scans/afni_unwarp_test/r01_unwarped_1vol.nii \
             -blocks volreg \
             -volreg_align_to first \
             -blip_forward_dset +29+FMRI_DISTORTION_PA_54sl.nii \
             -blip_reverse_dset +30+FMRI_DISTORTION_AP_54sl.nii
