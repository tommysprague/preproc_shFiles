# write labels for AFNI briks (for RF maps, for example)



ROOT="/deathstar/data/PrismaPilotScans"
SUBJ="CC"
SESS="CMRR_S6"
vistaDir=$ROOT/$SUBJ/$SESS/${SUBJ}_${SESS}_vista
RFdir=$vistaDir/Inplane/Original   # where the RF files are saved, incl. nii.gz (raw)

labels="VE phase ecc size exp x0 y0 b"

declare -a RF_prefix="RF_bc_ss5" # "RF_pctDet_surf")
declare -a RF_suffix=("gFit" "sFit" "fFit")

for p in "${RF_prefix[@]}"; do


  for s in "${RF_suffix[@]}"; do


    # USE AFNI to load RF file, save a brik/head, label, convert to nii, delete intermed. files

    # copy as BRIK/HEAD
    3dcopy $RFdir/${p}-${s}.nii.gz $RFdir/${p}-${s}

    # apply "labels" to each brik (should probably check right # of briks, etc...)
    3drefit -relabel_all_str "$labels" $RFdir/${p}-${s}+orig

    # copy the result to vistaDir for visualization!
    3dcopy $RFdir/${p}-${s}+orig $vistaDir/${p}-${s}.nii.gz



    # clean intermediate files
    rm $RFdir/*.BRIK
    rm $RFdir/*.HEAD


  done
done
