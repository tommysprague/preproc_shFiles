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

## SETTINGS ###################################################################
CORES=12       # number of jobs (should equal the number of cores you have)

fSES=1          # first session number
SESS=1          # number of sessions
FWHM=0          # spatial smoothing (mm)
REWINDTRS=0     # number of TRs to end of rewind
###############################################################################

for ((s=fSES;s<=SESS;s++)); do

    ## set number of runs for current session
    RUN=`ls -l SESS$s/raw/*func* | wc -l`
    rm ./list.txt; for ((i=1;i<=RUN;i++)); do echo $i >> ./list.txt; done
    
    # Linear detrend (for  mean estimation)
    cat ./list.txt | parallel -P $CORES \
    3dDetrend -prefix SESS$s/func_tmp_det{}.nii.gz\
              -polort 2 SESS$s/reg_func{}_to_T1.nii.gz
          
    cat ./list.txt | parallel -P $CORES \
    3dTstat -prefix SESS$s/func_tmp_mean{}.nii.gz \
            -mean SESS$s/reg_func{}_to_T1.nii.gz
    
    cat ./list.txt | parallel -P $CORES \
    3dTstat -prefix SESS$s/func_tmp_detMean{}.nii.gz \
            -mean SESS$s/func_tmp_det{}.nii.gz
              
    cat ./list.txt | parallel -P $CORES \
    3dcalc -prefix SESS$s/func_detrend{}.nii.gz \
           -a SESS$s/func_tmp_det{}.nii.gz \
           -b SESS$s/func_tmp_mean{}.nii.gz \
           -c SESS$s/func_tmp_detMean{}.nii.gz \
           -expr "'a+b-c'"
       
    rm SESS$s/*func_tmp*
    
    ## Voxel-wise mean timeseries
    cat ./list.txt | parallel -P $CORES \
    3dTstat -prefix SESS$s/func_mean{}.nii.gz \
            -mean SESS$s/func_detrend{}.nii.gz
    
    # skullstrip each
    cat ./list.txt | parallel -P $CORES \
    3dSkullStrip -prefix SESS$s/func_brain{}.nii.gz -input SESS$s/func_detrend{}.nii.gz
    
    # create mask of that
    cat ./list.txt | parallel -P $CORES \
    3dAutomask -prefix SESS$s/func_mask{}.nii.gz SESS$s/func_brain{}.nii.gz
    
    # ## Global mean timeseries & derivative
    # for ((i=1;i<=RUN;i++)); do 
    # 3dmaskave -mask SESS$s/func_mask$i.nii.gz \
    #     -quiet SESS$s/func_detrend$i.nii.gz > SESS$s/params_globalMean$i.1D
    # done

    # bandpass + smooth
    cat ./list.txt | parallel -P $CORES \
        3dTproject -prefix SESS$s/func_hipass{}.nii.gz \
                   -blur $FWHM \
                   -mask SESS$s/func_mask{}.nii.gz \
                   -passband 0.008 99999 \
                   -input SESS$s/func_detrend{}.nii.gz
                   
    # percent signal change
    cat ./list.txt | parallel -P $CORES \
    3dcalc -prefix SESS$s/func_normPct{}.nii.gz \
           -a SESS$s/func_hipass{}.nii.gz \
           -b SESS$s/func_mean{}.nii.gz \
           -c SESS$s/func_mask{}.nii.gz \
           -expr "'(a/b) * c * 100'"
    

done

