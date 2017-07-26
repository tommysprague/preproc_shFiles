# smooth on the SUMA surface
#
# adapted from surfsmooth.sh, from KD
# adapted from surfsmooth_tcs.sh, from TCS
# TCS, 4/10/2017
# UDPATED TCS 7/21/2017 for PRISMA Multiband data (processed w/ afni_proc.py)
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
# --- SUBJ_FUNCsess.results/pb0X.SUBJ_FUNCsess.?h.r0?.[surf/blur].niml.dset
#
# data have already been smoothed in the surface from afni_proc.py, so here we're just projecting back into volume
#
# Proceeds by doing this for LH, RH independently (due to how SUMA handles things),
# then combining these images and saving as a new _ss.nii.gz dataset
#
#
# meant to be run from subj ROOT directory
#
# At conclusion of vol --> surf --> vol transforms, resulting nii.gz's are poorly built - they're
# missing info about # TRs and they're written to 5D
# - loops through runs within session and 'squeezes' the nifti using preproc_mFiles toolbox niftiSqueeze
# - looks up TR from the $FUNCSESS and uses that to reset TR value in nifti
# - transforms data to RAI, which is the final space we want *all* data in





ROOT=/deathstar/data/PrismaPilotScans
SUBJ=CC
ANATSUBJ=CCanat_fs6b
FUNCSESS=MGSMap6S
#FUNCSESS=RF1
#FUNC=bar_width_1_pct
FWHM=5
CORES=5

TR=1.2   # TODO: figure out how to get this dynamically per run (hard w/ parallel command...)

# TODO: loop over funcsess (also, loop over _ss5/_surf files as sensically as possible...)


PREPROC_DIR=$ROOT/$SUBJ/$FUNCSESS/${SUBJ}_${FUNCSESS}.results/

# OR ss5
FUNCSUFFIX=surf  # when saving (bar_widht_1_XXX), what to use? usually surf or ss$FWHM
SOURCESTR=surf   # pb0X.$SOURCESTR.niml.dset (typically blur or surf)
PBNUM=pb03

FUNCPREFIX_lh=$PBNUM.${SUBJ}_${FUNCSESS}.lh.r*.$SOURCESTR.niml.dset #"pb03.CCpp2_CMRR6_unwarp_bc.lh.r*.surf.niml.dset"
FUNCPREFIX_rh=$PBNUM.${SUBJ}_${FUNCSESS}.rh.r*.$SOURCESTR.niml.dset #"pb03.CCpp2_CMRR6_unwarp_bc.rh.r*.surf.niml.dset"


FUNCPREFIX=${SUBJ}_${FUNCSESS} #"pb04.CCpp2_CMRR4_unwarp_ss.lh.r03.blur.niml.dset"

cd $PREPROC_DIR


rm $ROOT/$SUBJ/$FUNCSESS/func_list_lh.txt; for FUNC in $FUNCPREFIX_lh; do printf "%s\n" $FUNC | cut -f -4 -d . >> $ROOT/$SUBJ/$FUNCSESS/func_list_lh.txt; done
rm $ROOT/$SUBJ/$FUNCSESS/func_list_rh.txt; for FUNC in $FUNCPREFIX_rh; do printf "%s\n" $FUNC | cut -f -4 -d . >> $ROOT/$SUBJ/$FUNCSESS/func_list_rh.txt; done

# list of output filenames
rm $ROOT/$SUBJ/$FUNCSESS/func_list.txt; for FUNC in $FUNCPREFIX_lh; do printf "%s.%s\n" $FUNC | cut -f 2,4 -d .   >> $ROOT/$SUBJ/$FUNCSESS/func_list.txt; done

# list of runs
rm $ROOT/$SUBJ/$FUNCSESS/run_list.txt; for FUNC in $FUNCPREFIX_lh; do printf "%s.%s\n" $FUNC | cut -f 4 -d .   >> $ROOT/$SUBJ/$FUNCSESS/run_list.txt; done



# move a volreg run (pb02) to FUNCSESS, rename appropriately`
3dcopy $PREPROC_DIR/pb02.${SUBJ}_${FUNCSESS}.r01.volreg+orig $ROOT/$SUBJ/$FUNCSESS/${FUNCPREFIX}_r01.nii.gz


cd $ROOT/$SUBJ


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
-prefix ./${FUNCSESS}/{}_$FUNCSUFFIX.nii.gz \
-sdata $PREPROC_DIR/{}.$SOURCESTR.niml.dset

cat ./$FUNCSESS/func_list_rh.txt | parallel -P $CORES \
3dSurf2Vol \
-spec ./${ANATSUBJ}/SUMA/${ANATSUBJ}_rh.spec \
-surf_A smoothwm \
-surf_B pial \
-sv ./${ANATSUBJ}/SUMA/${ANATSUBJ}_SurfVol+orig. \
-grid_parent ./${FUNCSESS}/${FUNCPREFIX}_r01.nii.gz \
-map_func ave \
-f_steps 10 \
-prefix ./${FUNCSESS}/{}_$FUNCSUFFIX.nii.gz \
-sdata $PREPROC_DIR/{}.$SOURCESTR.niml.dset


# RENAME THEM TO SOMETHING SENSICAL
# TODO: figure out how to dynamically change pb03/pb04?
cat ./$FUNCSESS/run_list.txt | parallel -P $CORES \
mv ./$FUNCSESS/$PBNUM.$FUNCPREFIX.rh.{}_$FUNCSUFFIX.nii.gz ./$FUNCSESS/rh_${FUNCPREFIX}.{}_$FUNCSUFFIX.nii.gz

cat ./$FUNCSESS/run_list.txt | parallel -P $CORES \
mv ./$FUNCSESS/$PBNUM.$FUNCPREFIX.lh.{}_$FUNCSUFFIX.nii.gz ./$FUNCSESS/lh_${FUNCPREFIX}.{}_$FUNCSUFFIX.nii.gz


cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
3dcalc -prefix ./${FUNCSESS}/{}_$FUNCSUFFIX.nii.gz -a ./${FUNCSESS}/lh_{}_$FUNCSUFFIX.nii.gz -b ./${FUNCSESS}/rh_{}_$FUNCSUFFIX.nii.gz -expr "'(a+b)/(notzero(a)+notzero(b))'"


# squeeze & reset TR [[_surf]]
for FUNC in $(cat ./$FUNCSESS/func_list.txt);
do
  matlab -nosplash -nojvm -nodesktop -r "setup_paths_RFs; nii=niftiRead('./${FUNCSESS}/${FUNC}_$FUNCSUFFIX.nii.gz'); nii=niftiSqueeze(nii,${TR}); niftiWrite(nii,'./${FUNCSESS}/${FUNC}_$FUNCSUFFIX.nii.gz'); exit;";
done


# finally, put them in RAI (preferred by vista; all ROIs in this orientation)
cat ./$FUNCSESS/func_list.txt | parallel -P $CORES \
3dresample -overwrite -prefix ./${FUNCSESS}/{}_$FUNCSUFFIX.nii.gz -orient rai -inset ./${FUNCSESS}/{}_$FUNCSUFFIX.nii.gz
