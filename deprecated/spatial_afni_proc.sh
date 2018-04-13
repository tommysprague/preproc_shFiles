# AFNI, run unwarping, motion correction, etc

SUBJ=CC
SESS=MGSMap1

EXPTDIR=wmChoose_scanner

cd /deathstar/data/$EXPTDIR/$SUBJ/$SESS/

BLURAMT=0  # if 0, don't run "blur" block, otherwise, run it w/ BLURAMT smoothing


# NOTE: for selective indexing, use: -dsets  `ls run{startrun..endrun}_bc*.nii.gz`


if [ $BLURAMT = 0 ]
then
  # no blurring (note: for CC...., add _fs6b after SUBJanat)
  afni_proc.py -subj_id ${SUBJ}_${SESS} \
  -dsets /deathstar/data/$EXPTDIR/$SUBJ/$SESS/run09_bc.nii.gz /deathstar/data/$EXPTDIR/$SUBJ/$SESS/run10_bc.nii.gz /deathstar/data/$EXPTDIR/$SUBJ/$SESS/run11_bc.nii.gz  \
  -copy_anat /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/brainmask.nii \
  -anat_has_skull no \
  -blocks align volreg surf \
  -volreg_align_e2a \
  -volreg_base_ind 3 0 \
  -volreg_warp_dxyz 2 \
  -align_opts_aea -cost lpc+ZZ -giant_move \
  -surf_anat /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/${SUBJ}anat_fs6b_SurfVol+orig \
  -surf_spec /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/${SUBJ}anat_fs6b_?h.spec \
  -blip_forward_dset blip_for3_bc.nii.gz  \
  -blip_reverse_dset blip_rev3_bc.nii.gz \
  -execute

else

  # for surface blurring
  afni_proc.py -subj_id ${SUBJ}_${SESS} \
  -dsets /deathstar/data/$EXPTDIR/$SUBJ/$SESS/run*_bc.nii.gz  \
  -copy_anat /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/brainmask.nii \
  -blocks align volreg surf blur \
  -volreg_align_e2a \
  -volreg_base_ind 3 0 \
  -volreg_warp_dxyz 2 \
  -align_opts_aea -cost lpc+ZZ -giant_move \
  -blur_size $BLURAMT \
  -surf_anat /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/${SUBJ}anat_fs6b_SurfVol+orig \
  -surf_spec /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/${SUBJ}anat_fs6b_?h.spec \
  -blip_forward_dset blip_for3_bc.nii.gz  \
  -blip_reverse_dset blip_rev3_bc.nii.gz \
  -execute

fi
