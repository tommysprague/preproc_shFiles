# EII=1; for i in *.nii.gz; do ls $i; \
# NEWNAME=func`printf $EII`.nii.gz; \
# echo Renaming $i to $NEWNAME; \
# mv $i $NEWNAME; EII=`expr $EII + 1`; done
#
# adapted from /KD/spatial.sh in this directory - adding features to 1dplot motion params,
# loop through custom-named sessions (and eventually load them...)

## SETTINGS ###
CORES=12             # jobs in parallel
TR_FROM=3            # first TR to write out --- number you want to crop
RES=2.5             # upsampled EPI resolution

ROOT="/deathstar/data/PrismaPilotScans"
SCANDIR="CCpp2_scans"
SUBJ="CCpp2"

DATA_PREFIX=+cmrr_mbepi_s6_2mm
SUBJ_PREFIX="+"

SUFFIX=_54sl

# FIRST: create topup files
# NOTE: will need to make a topup_params.txt file already

PARAMS="topup_params_54sl.txt"

# for now, we'll manually change these...not ideal...
AP_SCAN="23+FMRI_DISTORTION_AP_54sl/+23+FMRI_DISTORTION_AP_54sl.nii"
PA_SCAN="24+FMRI_DISTORTION_PA_54sl/+24+FMRI_DISTORTION_PA_54sl.nii"

# 3dTcat them
3dTcat -prefix $ROOT/$SCANDIR/${SUBJ}_topup${SUFFIX}.nii.gz $ROOT/$SCANDIR/$AP_SCAN $ROOT/$SCANDIR/$PA_SCAN

# now run topup
cd $ROOT/$SCANDIR
#fsl5.0-topup --imain=CCpp2_topup_54sl.nii --datain=topup_params_54sl.txt --out=topup_results_54sl --config=b02b0.cnf --fout=field_54sl --iout=unwarped_54sl
fsl5.0-topup --imain=${SUBJ}_topup${SUFFIX}.nii --datain=topup_params${SUFFIX}.txt --out=topup_results${SUFFIX} --config=b02b0.cnf --fout=field${SUFFIX} --iout=unwarped${SUFFIX}


# find all other niis
# need to loop over directories in SCANDIR and find .nii's within, put the directory into a txt file, evaluate that w/ parallel


#ls  *+cmrr_mbepi_s4_2mm/*.nii | printf "%s\n"

# make a list of scans to loop through
rm ./tmp.txt
printf "%s\n" `ls *${DATA_PREFIX}/*${DATA_PREFIX}.nii` >> ./tmp.txt #list${SUFFIX}.txt

rm ./list${SUFFIX}.txt
for ff in  `(cat tmp.txt)`; do
  #fname=`echo $ff | cut -f 1 -d .`
  fname=`echo $ff | cut -f 1 -d +`
  printf "%s\n" $fname >> ./list${SUFFIX}.txt
  #printf "%s\n" | `cut -f 1 -d .` >> ./list${SUFFIX}.txt
done

# make output directory
mkdir $ROOT/$SCANDIR/unwarped

#cat ./list${SUFFIX}.txt | parallel -P $CORES \
#`echo {}`

# run apply-topup
cat ./list${SUFFIX}.txt | parallel -P $CORES \
fsl5.0-applytopup --imain={}${DATA_PREFIX}/${SUBJ_PREFIX}{}${DATA_PREFIX}.nii --inindex=4 --datain=topup_params${SUFFIX}.txt --topup=topup_results${SUFFIX} --out=./unwarped/${SUBJ_PREFIX}{}${DATA_PREFIX}_unwarped --method=jac -v
#fsl5.0-applytopup --imain={} --inindex=4 --datain=topup_params${SUFFIX}.txt --topup=topup_results${SUFFIX} --out=unwarped/`cut -f 1 -d / "{}"`_topup --method=jac -v
