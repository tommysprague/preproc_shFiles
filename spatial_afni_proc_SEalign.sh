# AFNI, run unwarping, motion correction, etc

# NOTE: moved a bunch of other calls to misc_afni_proc.sh

SUBJ=CC
SESS=RF1

EXPTDIR=vRF_tcs

STARTRUN=05
ENDRUN=08

cd /deathstar/data/$EXPTDIR/$SUBJ/$SESS/

SEtarg=2  # which scan (blip pair) is the spin-echo target

# for now, use the first as the target
# trying out making a spin-echo target for moco/alignment
afni_proc.py -subj_id SEtarget$SEtarg \
             -dsets /deathstar/data/$EXPTDIR/$SUBJ/$SESS/blip_for*_bc.nii.gz \
             -copy_anat /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/brainmask.nii \
             -blocks  volreg \
             -volreg_base_ind $SEtarg 0 \
             -blip_forward_dset blip_for${SEtarg}_bc.nii.gz  \
             -blip_reverse_dset blip_rev${SEtarg}_bc.nii.gz \
             -execute


# copy the pb02 images as SEtarget images in /SESS/directory
# num runs
#RUN=`ls -l SEtarget1/raw/func* | wc -l`
#rm ./list.txt; for ((i=1;i<=RUN;i++)); do printf "%02.f\n" $i >> ./list.txt; done

# average all blip volumes after coregistration (concatenate, then mean)
3dTcat -prefix SEtarget$SEtarg.results/SEtarget${SEtarg}_all_blip.nii.gz SEtarget$SEtarg.results/pb02.SEtarget$SEtarg.r*+orig.BRIK
3dTstat -mean -prefix SEtarget$SEtarg.nii.gz SEtarget$SEtarg.results/SEtarget${SEtarg}_all_blip.nii.gz

# put them in the same coord system as the functional data (which matches AP/PA scans)
3dresample -prefix SEtarget$SEtarg.nii.gz -overwrite -master blip_for${SEtarg}_bc.nii.gz -inset SEtarget$SEtarg.nii.gz

# let's try below with -volreg_base_dset as the mean unwarped & aligned spin-echo image
# this means both EPI-->EPI moco registration and EPI-->anat anat registration will occur on this image
# (so we'll need to carefully check the EPI/EPI and anat/EPI alignment...)

# where do we put results?
RESULTSDIR=${SUBJ}_${SESS}_r${STARTRUN}to${ENDRUN}_SEalign

# no blurring (note: for CC...., add _fs6b after SUBJanat)
afni_proc.py -subj_id $RESULTSDIR \
             -dsets $(printf "/deathstar/data/$EXPTDIR/$SUBJ/$SESS/run%02.f_bc.nii.gz " `seq -s " " $STARTRUN $ENDRUN`) \
             -copy_anat /deathstar/data/$EXPTDIR/$SUBJ/${SUBJ}anat_fs6b/SUMA/brainmask.nii \
             -blocks align volreg \
             -volreg_align_e2a \
             -volreg_base_dset SEtarget$SEtarg.nii.gz \
             -anat_has_skull no \
             -align_opts_aea -cost lpc+ZZ -giant_move \
             -blip_forward_dset blip_for${SEtarg}_bc.nii.gz  \
             -blip_reverse_dset blip_rev${SEtarg}_bc.nii.gz \
             -execute





# -dsets /deathstar/data/$EXPTDIR/$SUBJ/$SESS/run{$STARTRUN..$ENDRUN}_bc.nii.gz \

# must make STARTRUN; ENDRUN base10...$((10#$STARTRUN))

# loop from end to beginning of run list, converting all r## (1-n) to startrun:endrun
runidx=$(( $((10#$ENDRUN)) - $((10#$STARTRUN)) + 1 ))
for (( i=$((10#$ENDRUN)); i>=$((10#$STARTRUN)); i-- ))
do
  echo Renaming run $runidx to run $i

# perl rename str
  repstr=s/`printf "r%02.f" $runidx`/`printf "r%02.f" $i`/
  rename $repstr `printf "$RESULTSDIR.results/*.r%02.f.*" $runidx`
  #echo `printf "$RESULTSDIR/*.r%02.f.*" $runidx`
  runidx=$(( $runidx - 1 ))
done


# make QC files ($SUBJ/align_QC/$SUBJ_$SESS_mu_r$i.nii.gz)

mkdir ../align_QC

for ii in $(seq -s " " $STARTRUN $ENDRUN)
do
  rnum=$(printf "%02.f" $ii)
  3dTstat -mean -prefix ../align_QC/${SUBJ}_${SESS}_mu_r$rnum.nii.gz $RESULTSDIR.results/pb02.$RESULTSDIR.r$rnum.volreg+orig
done

# examples of using parallel w/ multiple columns of arguments from file-C regexp
#Column separator. The input will be treated as a table with regexp separating the columns. The n'th column can be access using {n} or {n.}. E.g. {3} is the 3rd column.

#--colsep implies --trim rl.

#regexp is a Perl Regular Expression: http://perldoc.perl.org/perlre.html
