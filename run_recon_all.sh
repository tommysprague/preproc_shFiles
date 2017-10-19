#!/bin/bash


SUBJ=$1

cd $SUBJECTS_DIR

recon-all -autorecon1 -autorecon2 -autorecon3 -sd $SUBJECTS_DIR -subjid ${SUBJ}anat \
    -i $SUBJECTS_DIR/${SUBJ}src/T1_1.nii* \
    -i $SUBJECTS_DIR/${SUBJ}src/T1_2.nii* \
    -i $SUBJECTS_DIR/${SUBJ}src/T1_3.nii* \
    -T2 $SUBJECTS_DIR/${SUBJ}src/T2_1.nii* \
    -expert $PREPROC/hires_expert \
    -T2pial -parallel -openmp 16 -hires
