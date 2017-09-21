EXPTDIR=/deathstar/data/vRF_tcs
SUBJ=CC
SESS=RF25mm

cat $EXPTDIR/$SUBJ/$SESS/${SUBJ}_${SESS}_SEtargets.txt | while read line
do

set $line
  echo $1
  echo $2
  echo $3

  SEtarg=$1
  startrun=$2
  endrun=$3
  echo SEtarg: $SEtarg
  echo start: $startrun
  echo end: $endrun
  #echo start: $2
  #echo

#  SEtarg=$(cut -d " " -f 1 < $line)
  #printf "SEtarg: %s\n" $SEtarg
  #printf ""
  #echo $line | cut -d " " -f 2
  #echo $line | cut -d " " -f 3

#echo startrun: $startrun
#echo endrun: $endrun
done
