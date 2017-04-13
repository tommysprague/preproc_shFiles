# EII=1; for i in *.nii.gz; do ls $i; \
# NEWNAME=func`printf $EII`.nii.gz; \
# echo Renaming $i to $NEWNAME; \
# mv $i $NEWNAME; EII=`expr $EII + 1`; done

## SETTINGS ###
CORES=12             # jobs in parallel
fSES=1               # first session number
SESS=1               # last session number
TR_FROM=3            # first TR to write out --- number you want to crop
TR_TO=122            # last TR to write out --- length - 1
RES=2.5             # upsampled EPI resolution


for ((s=fSES;s<=SESS;s++)); do

    # count runs
    RUN=`ls -l SESS$s/raw/func* | wc -l`

    # convert to BRIKHEAD
    3dcopy SESS${s}/raw/cal_synth.nii SESS$s/anat_cal # removed .gz
    3dcopy anat_T1_brain.nii anat_T1_brain  # removed .gz

    # T1 to CAL ...
    align_epi_anat.py -anat anat_T1_brain+orig. -epi SESS${s}/anat_cal+orig. \
                      -epi_base 0 -epi2anat -suffix _to_T1 \
                      -anat_has_skull no -epi_strip None \
                      -volreg off -tshift off -deoblique on \
                      -cost lpc -giant_move -partial_axial

    # num runs
    RUN=`ls -l SESS${s}/raw/func* | wc -l`
    rm ./list.txt; for ((i=1;i<=RUN;i++)); do echo $i >> ./list.txt; done

    # make output directories
    cat ./list.txt | parallel -P $CORES \
    mkdir SESS$s/run{}

    # make briks
    cat ./list.txt | parallel -P $CORES \
    3dcalc -prefix SESS$s/run{}/func{} -expr 'a' -a SESS$s/raw/func{}.nii[$TR_FROM..$TR_TO]   # removed .gz, to align w/ scanner data

    # make targets
    3dresample -prefix SESS$s/target -dxyz $RES $RES $RES -rmode Cu -inset SESS$s/anat_cal_to_T1+orig.

    # EPI to WHEPI_to_T1
    cat ./list.txt | parallel -P $CORES \
    align_epi_anat.py -epi SESS${s}/run{}/func{}+orig. \
                      -anat SESS${s}/target+orig. \
                      -epi_base 0 -epi2anat -suffix _to_T1 \
                      -anat_has_skull no -epi_strip None \
                      -volreg on -volreg_method 3dvolreg \
                      -cost lpa -giant_move -save_vr -deoblique on \
                      -Allineate_opts '-float -final wsinc5 -mast_dxyz 2.5 2.5 2.5' \
                      -tshift on -output_dir SESS$s/run{} \
                      -big_move

# TS, altered above to match target resolution (2.5)

    # convert to nifti
    cat ./list.txt | parallel -P $CORES \
    3dcopy SESS$s/run{}/func{}_to_T1+orig. SESS$s/reg_func{}_to_T1.nii.gz

    cat ./list.txt | parallel -P $CORES \
    rm SESS$s/run{}/*orig*

    # TCS: need to save out 1dplot of the motion params
    mkdir SESS$s/figures
    1dplot -sep -plabel SESS$s/run{} -png SESS$s/figures/run{}_motion.png run{}/func{}_tsh_vr_motion.1D 

done

# SESSN final move
for ((s=fSES;s<=SESS;s++)); do

    # compute mask
    3dMean -prefix SESS$s/func_to_T1_mu.nii.gz SESS$s/reg*_to_T1.nii.gz
    3dTstat -prefix SESS$s/func_to_T1_mumu.nii.gz SESS$s/func_to_T1_mu.nii.gz
    # 3dAutomask -prefix SESS$s/func_mask.nii.gz -clfrac 0.5 -peels 3 -erode 1 SESS$s/func_to_T1_mumu.nii.gz
    3dSkullStrip -prefix SESS$s/func_to_T1_mumu_brain.nii.gz -input SESS$s/func_to_T1_mumu.nii.gz
    3dAutomask -prefix SESS$s/func_mask.nii.gz SESS$s/func_to_T1_mumu_brain.nii.gz

done
