## Dual Phase Encoded Stimuli Mean Generation w. AFNI & MATLAB
## Allows for multi-session registrations

## June 19th 2012, Joseph Viviano
##
## SESS1 ... SESSn folders, func files
##
# rename functional files in /SESSn

# EII=1; for i in *.nii.gz; do ls $i; \
# NEWNAME=func`printf $EII`.nii.gz; \
# echo Renaming $i to $NEWNAME; \
# mv $i $NEWNAME; EII=`expr $EII + 1`; done

# This script:
# 1) Deletes initial TRs
# 2) Linear detrend
# 3) Records timeseries mean
# 4) Records global timeseries mean
# 5) Filtering:
#   a) detrend (polort = 2)
#   b) highpass (f = 0.0119 Hz, 84 Seconds)
#   c) regression of filtered mean global signal
#   d) smooth within brain mask
# 6) Normalize: mean (% signal change) & variance
#



## SETTINGS ###################################################################
CORES=12       # number of jobs (should equal the number of cores you have)

#fSES=1          # first session number
#SESS=1          # number of sessions
FWHM=0          # spatial smoothing (mm)
REWINDTRS=0     # number of TRs to end of rewind
###############################################################################

ROOT="/deathstar/data/ssPri_scanner_afni"
SUBJ="AB"


declare -a SESSIONS=("Map1" "Map2")

# get in the right directory - root directory of a given subj
cd $ROOT/$SUBJ

#for ((s=fSES;s<=SESS;s++)); do
for s in "${SESSIONS[@]}"; do




    ## set number of runs for current session
    RUN=`ls -l $s/raw/*func* | wc -l`
    rm ./list.txt; for ((i=1;i<=RUN;i++)); do printf "%02.f\n" $i >> ./list.txt; done

    # Linear detrend (for  mean estimation)
    cat ./list.txt | parallel -P $CORES \
    3dDetrend -prefix $s/func_tmp_det{}.nii.gz\
              -polort 1 $s/reg_func{}_to_T1.nii.gz

    cat ./list.txt | parallel -P $CORES \
    3dTstat -prefix $s/func_tmp_mean{}.nii.gz \
            -mean $s/reg_func{}_to_T1.nii.gz

    cat ./list.txt | parallel -P $CORES \
    3dTstat -prefix $s/func_tmp_detMean{}.nii.gz \
            -mean $s/func_tmp_det{}.nii.gz

    cat ./list.txt | parallel -P $CORES \
    3dcalc -prefix $s/func_detrend{}.nii.gz \
           -a $s/func_tmp_det{}.nii.gz \
           -b $s/func_tmp_mean{}.nii.gz \
           -c $s/func_tmp_detMean{}.nii.gz \
           -expr "'a+b-c'"

    rm $s/*func_tmp*

    ## here, we're left with linear-detrended data at its original mean


    ## Voxel-wise mean over timeseries (this is identical tot he tmp-mean file removed above...)
    cat ./list.txt | parallel -P $CORES \
    3dTstat -prefix $s/func_mean{}.nii.gz \
            -mean $s/func_detrend{}.nii.gz

    # skullstrip each (note: this looked like it was missing some brain for KD); default -clfrac 0.5
#    cat ./list.txt | parallel -P $CORES \
#    3dSkullStrip -prefix $s/func_brain{}.nii.gz -input $s/func_detrend{}.nii.gz -push_to_edge

    # create mask of that
#    cat ./list.txt | parallel -P $CORES \
#    3dAutomask -prefix $s/func_mask{}.nii.gz -clfrac 0.1 $s/func_brain{}.nii.gz




    # ## Global mean timeseries & derivative
    # for ((i=1;i<=RUN;i++)); do
    # 3dmaskave -mask SESS$s/func_mask$i.nii.gz \
    #     -quiet SESS$s/func_detrend$i.nii.gz > SESS$s/params_globalMean$i.1D
    # done

    # bandpass + smooth
    cat ./list.txt | parallel -P $CORES \
        3dTproject -prefix $s/func_hipass{}.nii.gz \
                   -blur $FWHM \
                   -mask anat_EPI_mask.nii.gz \
                   -passband 0.008 99999 \
                   -input $s/func_detrend{}.nii.gz

    # percent signal change
#    cat ./list.txt | parallel -P $CORES \
#    3dcalc -prefix $s/func_normPct{}.nii.gz \
#           -a $s/func_hipass{}.nii.gz \
#           -b $s/func_mean{}.nii.gz \
#           -c anat_EPI_mask.nii.gz \
#           -expr "'(a/b) * c * 100'"
# -c anat_EPI_mask.nii.gz


    # percent signal change - computed w/ detrended rather than hi-pass'd data; also remove 1
    cat ./list.txt | parallel -P $CORES \
    3dcalc -prefix $s/func_normPctDet{}.nii.gz \
           -a $s/func_detrend{}.nii.gz \
           -b $s/func_mean{}.nii.gz \
           -c anat_EPI_mask.nii.gz \
           -expr "'((a/b)-1) * c * 100'"





done
