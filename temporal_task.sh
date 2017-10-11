##!/bin/bash
#
# temporal_task.sh
#
# GOALS:
# [assumes afni_proc.py already run, we're working w/ volreg files]

# This script:
# 1) resample to RAI orientation
# 2) saves out a voxel-wise mean
# 3) linear detrend
# 4) convert to PSC


# can process either "func" or "surf" files (4th arg), which have already been pre-processed


DATAROOT="/deathstar/data"

EXPTDIR=$1

SUBJ=$2
SESS=$3

DATATYPE=$4 # surf or ${DATATYPE}

ROOT=$DATAROOT/$EXPTDIR


# get in the right directory - root directory of a given subj
cd $ROOT/$SUBJ

# figure out how many cores...

RUN=`ls -l $DATAROOT/$EXPTDIR/$SUBJ/$SESS/${DATATYPE}*_volreg.nii.gz | wc -l`
rm ./list.txt; for ((i=1;i<=$RUN;i++)); do printf "%02.f\n" $i >> ./list.txt; done
CORES=$RUN

# convert to RAI
cat ./list.txt | parallel -P $CORES \
3dresample -prefix $SESS/${DATATYPE}{}_volreg.nii.gz \
           -orient rai \
           -overwrite  \
           -inset $SESS/${DATATYPE}{}_volreg.nii.gz

# Linear detrend (for  mean estimation)
cat ./list.txt | parallel -P $CORES \
3dDetrend -prefix $SESS/${DATATYPE}_tmp_det{}.nii.gz \
          -polort 1 $SESS/${DATATYPE}{}_volreg.nii.gz

cat ./list.txt | parallel -P $CORES \
3dTstat -prefix $SESS/${DATATYPE}_tmp_mean{}.nii.gz \
        -mean $SESS/${DATATYPE}{}_volreg.nii.gz

cat ./list.txt | parallel -P $CORES \
3dTstat -prefix $SESS/${DATATYPE}_tmp_detMean{}.nii.gz \
        -mean $SESS/${DATATYPE}_tmp_det{}.nii.gz

# add back in original mean
cat ./list.txt | parallel -P $CORES \
3dcalc -prefix $SESS/${DATATYPE}_volreg_detrend{}.nii.gz \
       -a $SESS/${DATATYPE}_tmp_det{}.nii.gz \
       -b $SESS/${DATATYPE}_tmp_mean{}.nii.gz \
       -c $SESS/${DATATYPE}_tmp_detMean{}.nii.gz \
       -overwrite \
       -expr "'a+b-c'"

rm $SESS/*${DATATYPE}_tmp*

## here, we're left with linear-detrended data at its original mean


## Voxel-wise mean over timeseries (this is identical tot he tmp-mean file removed above...)
cat ./list.txt | parallel -P $CORES \
3dTstat -prefix $SESS/${DATATYPE}_volreg_mean{}.nii.gz -overwrite \
        -mean $SESS/${DATATYPE}_volreg_detrend{}.nii.gz


# percent signal change - computed w/ detrended rather than hi-pass'd data; also remove 1
cat ./list.txt | parallel -P $CORES \
3dcalc -prefix $SESS/${DATATYPE}_volreg_normPctDet{}.nii.gz \
       -a $SESS/${DATATYPE}_volreg_detrend{}.nii.gz \
       -b $SESS/${DATATYPE}_volreg_mean{}.nii.gz \
       -c surfanat_brainmask_master.nii.gz \
       -overwrite \
       -expr "' and(ispositive(c),ispositive(b)) * ((a/b) - 1) *  100'"
