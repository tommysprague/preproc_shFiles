#!/bin/bash

cd /deathstar/data/Pri/KD/Pri1/

CORES=`cat KD_Pri1_SEtargets.txt | wc -l`
echo CORES=$CORES

cat KD_Pri1_SEtargets.txt | parallel -C ',' \
  echo Col 1: {1} \
       Col 2: {2} \
       Col 3: {3}
