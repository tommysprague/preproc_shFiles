##!/bin/bash
#
# temporal_task.sh
#
# adapted/testing from temporal_task_tcs.sh
#
# GOALS:
# [assumes afni_proc.py already run, we're working w/ volreg files]
# TODO: incorporate support for surfsmooth'd data
# TODO: incorporate multiple distortion correction iterations

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
#CORES=12       # number of jobs (should equal the number of cores you have)

#fSES=1          # first session number
#SESS=1          # number of sessions
#FWHM=0          # spatial smoothing (mm)
#REWINDTRS=0     # number of TRs to end of rewind
###############################################################################

DATAROOT="/deathstar/data"
#SUBJ="CC"



EXPTDIR=$1

SUBJ=$2
SESS=$3

DATATYPE=$4 # surf or ${DATATYPE}




ROOT=$DATAROOT/$EXPTDIR

#declare -a SESSIONS=("MGSMap25mm_MB4")

# get in the right directory - root directory of a given subj
cd $ROOT/$SUBJ

#for ((s=fSES;s<=SESS;s++)); do
#for s in "${SESSIONS[@]}"; do

    # FUNCPRE="pb02.${SUBJ}_${SESS}*.r"
    # FUNCSUF=".volreg+orig.BRIK"
    # #FUNCSTR="pb02.${SUBJ}_${s}.r*.volreg+orig.BRIK"
    #
    # ## set number of runs for current session
    # #RUN=`ls -l $SESS/raw/*${DATATYPE}* | wc -l`
# CORES=`ls -l $SESS/${SUBJ}_${SESS}*.results/${FUNCPRE}*${FUNCSUF} | wc -l`
    # rm ./list.txt; for ((i=1;i<=RUN;i++)); do printf "%02.f\n" $i >> ./list.txt; done
    #
    #
    # # COPY BRIK/HEAD to nii/gz in super-directory
    # cat ./list.txt | parallel -P $CORES \
    # 3dcopy $SESS/${SUBJ}_${s}*_SEalign.results/${FUNCPRE}{}${FUNCSUF} $SESS/${DATATYPE}{}_volreg.nii.gz
    #


# figure out how many cores...

RUN=`ls -l $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${DATATYPE}*_volreg.nii.gz | wc -l`
rm ./list.txt; for ((i=1;i<=$RUN;i++)); do printf "%02.f\n" $i >> ./list.txt; done
CORES=$RUN

    # Linear detrend (for  mean estimation)
    cat ./list.txt | parallel -P $CORES \
    3dDetrend -prefix $SESS/${DATATYPE}_tmp_det{}.nii.gz\
              -polort 1 $SESS/${DATATYPE}{}_volreg.nii.gz

    cat ./list.txt | parallel -P $CORES \
    3dTstat -prefix $SESS/${DATATYPE}_tmp_mean{}.nii.gz \
            -mean $SESS/${DATATYPE}{}_volreg.nii.gz

    cat ./list.txt | parallel -P $CORES \
    3dTstat -prefix $SESS/${DATATYPE}_tmp_detMean{}.nii.gz \
            -mean $SESS/${DATATYPE}_tmp_det{}.nii.gz

    cat ./list.txt | parallel -P $CORES \
    3dcalc -prefix $SESS/${DATATYPE}_volreg_detrend{}.nii.gz \
           -a $SESS/${DATATYPE}_tmp_det{}.nii.gz \
           -b $SESS/${DATATYPE}_tmp_mean{}.nii.gz \
           -c $SESS/${DATATYPE}_tmp_detMean{}.nii.gz \
           -expr "'a+b-c'"

    rm $SESS/*${DATATYPE}_tmp*

    ## here, we're left with linear-detrended data at its original mean


    ## Voxel-wise mean over timeseries (this is identical tot he tmp-mean file removed above...)
    cat ./list.txt | parallel -P $CORES \
    3dTstat -prefix $SESS/${DATATYPE}_volreg_mean{}.nii.gz \
            -mean $SESS/${DATATYPE}_volreg_detrend{}.nii.gz

    # skullstrip each (note: this looked like it was missing some brain for KD); default -clfrac 0.5
#    cat ./list.txt | parallel -P $CORES \
#    3dSkullStrip -prefix $SESS/${DATATYPE}_brain{}.nii.gz -input $SESS/${DATATYPE}_detrend{}.nii.gz -push_to_edge

    # create mask of that
#    cat ./list.txt | parallel -P $CORES \
#    3dAutomask -prefix $SESS/${DATATYPE}_mask{}.nii.gz -clfrac 0.1 $SESS/${DATATYPE}_brain{}.nii.gz




    # ## Global mean timeseries & derivative
    # for ((i=1;i<=RUN;i++)); do
    # 3dmaskave -mask SESS$SESS/${DATATYPE}_mask$i.nii.gz \
    #     -quiet SESS$SESS/${DATATYPE}_detrend$i.nii.gz > SESS$SESS/params_globalMean$i.1D
    # done

    # bandpass + smooth
    # cat ./list.txt | parallel -P $CORES \
    #     3dTproject -prefix $SESS/${DATATYPE}_hipass{}.nii.gz \
    #                -blur $FWHM \
    #                -mask anat_EPI_mask.nii.gz \
    #                -passband 0.008 99999 \
    #                -input $SESS/${DATATYPE}_detrend{}.nii.gz

    # percent signal change
#    cat ./list.txt | parallel -P $CORES \
#    3dcalc -prefix $SESS/${DATATYPE}_normPct{}.nii.gz \
#           -a $SESS/${DATATYPE}_hipass{}.nii.gz \
#           -b $SESS/${DATATYPE}_mean{}.nii.gz \
#           -c anat_EPI_mask.nii.gz \
#           -expr "'(a/b) * c * 100'"
# -c anat_EPI_mask.nii.gz


    # percent signal change - computed w/ detrended rather than hi-pass'd data; also remove 1
    cat ./list.txt | parallel -P $CORES \
    3dcalc -prefix $SESS/${DATATYPE}_volreg_normPctDet{}.nii.gz \
           -a $SESS/${DATATYPE}_volreg_detrend{}.nii.gz \
           -b $SESS/${DATATYPE}_volreg_mean{}.nii.gz \
           -c surfanat_brainmask_master.nii.gz \
           -expr "'((a/b)-1) * ispositive(c) * 100'"


    # ensure we're in RAI - otherwise vista, etc, get pissed
    cat ./list.txt | parallel -P $CORES \
    3dresample -prefix $SESS/${DATATYPE}_volreg_normPctDet{}.nii.gz \
               -orient rai \
               -overwrite  \
               -inset $SESS/${DATATYPE}_volreg_normPctDet{}.nii.gz


    # save out a set of volumes depicting the mean (to comapre residual distortions)
    #3dTcat -prefix $SESS/${SUBJ}_${s}_meanruns.nii.gz $SESS/${DATATYPE}_volreg_mean*.nii.gz
