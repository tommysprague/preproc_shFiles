# prep_anat.sh
#
# Use this to set up symlink to processed freesurfer directory, and create surfanat files
# used for retinotopy. Run once per subj folder within an expt directory (not for each sess)
#
# Requires a pre-processed file already (need to sample on that grid)

EXPTDIR=/deathstar/data/vRF_tcs

SUBJ=KD
ANATSUBJ=${SUBJ}anat

# make symlink to freesurfer directory
ln -s $SUBJECTS_DIR/$ANATSUBJ $EXPTDIR/$SUBJ/$ANATSUBJ

# first preproc directorY: ls -d KD_RF1_r*_SEalign.results | head -1

# make surfanat files in $EXPTDIR/$SUBJ

PREPROC_DIR=$(ls -d $EXPTDIR/$SUBJ/*/${SUBJ}_*r*_SEalign.results | head -1)
PREPROC_IMG=$(ls $PREPROC_DIR/pb02.*.volreg+orig.BRIK | head -1)

3dresample -prefix $EXPTDIR/$SUBJ/surfanat_brainmask_master.nii.gz -master $PREPROC_IMG -rmode Cu -inset $SUBJECTS_DIR/$ANATSUBJ/SUMA/brainmask.nii
3dresample -prefix $EXPTDIR/$SUBJ/surfanat_brainmask_hires.nii.gz -dxyz 1.0 1.0 2.0 -rmode Cu -orient RAI -inset $EXPTDIR/$SUBJ/surfanat_brainmask_master.nii.gz
