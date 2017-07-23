# EII=1; for i in *.nii.gz; do ls $i; \
# NEWNAME=func`printf $EII`.nii.gz; \
# echo Renaming $i to $NEWNAME; \
# mv $i $NEWNAME; EII=`expr $EII + 1`; done
#
# adapted from /KD/spatial.sh in this directory - adding features to 1dplot motion params,
# loop through custom-named sessions (and eventually load them...)

## SETTINGS ###
CORES=12             # jobs in parallel
#fSES=1               # first session number
#SESS=1               # last session number
TR_FROM=3            # first TR to write out --- number you want to crop
#TR_TO=122            # last TR to write out --- length - 1 (or 3dinfo -nv *.nii)
RES=2.5             # upsampled EPI resolution

ROOT="/deathstar/data/PrismaPilotScans"
SUBJ="CC"
ANATSUBJ="CC_fs6b"

declare -a SESSIONS=("CMRR_S4" "CMRR_S6")
#declare -a SESSIONS=("RF1")
# get in the right directory - root directory of a given subj
cd $ROOT/$SUBJ

# which folders w/in subj folder?


#for ((s=fSES;s<=SESS;s++)); do
for s in "${SESSIONS[@]}"; do

    #echo $s
    #echo "PROCESSING SESSION: $ROOT/$SUBJ/$s"
    echo "PROCESSING SESSION: $ROOT/$SUBJ/$s"

    # count runs
    RUN=`ls -l $s/raw/func* | wc -l`

    # convert to BRIKHEAD
    3dcopy $s/raw/cal_synth.nii $s/anat_cal # removed .gz
    3dcopy $ANATSUBJ/SUMA/brain.nii anat_T1_brain  # removed .gz


    # T1 to CAL ...
    align_epi_anat.py -anat anat_T1_brain+orig. -epi $s/anat_cal+orig. \
                      -epi_base 0 -epi2anat -suffix _to_T1 \
                      -anat_has_skull no -epi_strip None \
                      -volreg off -tshift off -deoblique on \
                      -cost lpc -giant_move -partial_axial

    # num runs
    RUN=`ls -l $s/raw/func* | wc -l`
    rm ./list.txt; for ((i=1;i<=RUN;i++)); do printf "%02.f\n" $i >> ./list.txt; done

    # make output directories
    cat ./list.txt | parallel -P $CORES \
    mkdir $s/run{}

    # make briks
    cat ./list.txt | parallel -P $CORES \
    3dcalc -prefix $s/run{}/func{} -expr 'a' -a $s/raw/func{}.nii[$TR_FROM..$]   # removed .gz, to align w/ scanner data

    # make targets
    3dresample -prefix $s/target -dxyz $RES $RES $RES -rmode Cu -inset $s/anat_cal_to_T1+orig.

    # EPI to WHEPI_to_T1
    cat ./list.txt | parallel -P $CORES \
    align_epi_anat.py -epi $s/run{}/func{}+orig. \
                      -anat $s/target+orig. \
                      -epi_base 0 -epi2anat -suffix _to_T1 \
                      -anat_has_skull no -epi_strip None \
                      -volreg on -volreg_method 3dvolreg \
                      -cost lpa -giant_move -save_vr -deoblique on \
                      -Allineate_opts '-float -final wsinc5 -mast_dxyz 2.5 2.5 2.5' \
                      -tshift on -output_dir $s/run{} \
                      -big_move

# TS, altered above to match target resolution (2.5)

    # convert to nifti
    cat ./list.txt | parallel -P $CORES \
    3dcopy $s/run{}/func{}_to_T1+orig. $s/reg_func{}_to_T1.nii.gz

    cat ./list.txt | parallel -P $CORES \
    rm $s/run{}/*orig*

    # TCS: need to save out 1dplot of the motion params
    mkdir $s/figures
    cat ./list.txt | parallel -P $CORES\
    1dplot -sep -plabel $s/run{} -png $s/figures/run{}_motion.png $s/run{}/func{}_tsh_vr_motion.1D


    # convert anat_T1_brain back to nii gz
    3dcopy anat_T1_brain+orig anat_T1_brain.nii

done

# SESSN final move (ORIGINAL)
#for ((s=fSES;s<=SESS;s++)); do
#for s in "${SESSIONS[@]}"; do#
    # compute mask
    #3dMean -prefix $s/func_to_T1_mu.nii.gz $s/reg*_to_T1.nii.gz
    #3dTstat -prefix $s/func_to_T1_mumu.nii.gz $s/func_to_T1_mu.nii.gz
    # 3dAutomask -prefix SESS$s/func_mask.nii.gz -clfrac 0.5 -peels 3 -erode 1 SESS$s/func_to_T1_mumu.nii.gz
    #3dSkullStrip -prefix $s/func_to_T1_mumu_brain.nii.gz -input $s/func_to_T1_mumu.nii.gz
    #3dAutomask -prefix $s/func_mask.nii.gz $s/func_to_T1_mumu_brain.nii.gz

#done


# SESSN final move (UPDATED FROM KEVIN 3/16/2017)
# for each session, compute mean of all EPIs (reg_mumu.nii.gz), turn that into a mask (func_mask.nii.gz)
for s in "${SESSIONS[@]}"; do

    # compute mask
    3dMean -prefix $s/reg_mu.nii.gz $s/reg*_to_T1.nii.gz
    3dTstat -prefix $s/reg_mumu.nii.gz $s/reg_mu.nii.gz

    # resample anat_T1_brain into same space as reg_mumu_brain
    3dresample -prefix surfanat_mask.nii.gz -dxyz $RES $RES $RES -rmode Cu -inset anat_T1_brain+orig.


    3dcalc -prefix $s/reg_mumu_brain.nii.gz -expr 'a*b' -a surfanat_mask.nii.gz -b $s/reg_mumu.nii.gz
    3dAutomask -prefix $s/func_mask.nii.gz -dilate 1 $s/reg_mumu_brain.nii.gz

done

# BELOW: create a EPI-resolution mask (just any positive voxel from SUMA/FS brainmask.nii.gz)
#3dresample -prefix surfanat_brainmask.nii.gz -dxyz $RES $RES $RES -rmode Cu -inset $ANATSUBJ/SUMA/brainmask.nii

# this version does target, rather than expressing resolution? (identical to above)
3dresample -prefix surfanat_brainmask_master.nii.gz -master $s/reg_func01_to_T1.nii.gz -rmode Cu -inset $ANATSUBJ/SUMA/brainmask.nii
3dresample -prefix surfanat_brainmask_hires.nii.gz -dxyz 1.25 1.25 2.5 -rmode Cu -orient RAI -inset surfanat_brainmask_master.nii.gz

#3dresample -prefix surfanat_brainmask_hires.nii.gz -dxyz 1.25 1.25 1.25 -rmode Cu -inset $ANATSUBJ/SUMA/brainmask.nii  # try to make a pseudo-hi-res inplane?
#no, above adjusts the bounding box....


#3dAutomask -prefix anat_EPI_mask.nii.gz -clfrac 0.25 surfanat_brainmask.nii.gz
3dcalc -prefix anat_EPI_mask.nii.gz -expr 'ispositive(a)' -a surfanat_brainmask_master.nii.gz
#3dmask_tool -prefix anat_EPI_mask_fixed.nii.gz  -inputs anat_EPI_mask.nii.gz
#3dmask_tool -prefix anat_EPI_mask.nii.gz -inter -inputs `find . -name func_mask.nii.gz`
