# preproc_shFiles
Prisma preprocessing procedures (AFNI) at NYU for Curtis Lab

(work in progress)

Goal of our preprocessing is to align all functional data to a common space (freesurfer's recon-all) at a common resolution, dictated by *task* data. However, retinotopic mapping seems to work a bit better at higher resolutions (less partial voluming), so part of this procedure involves sampling into different volumetric coordinate systems.

## Retinotopic mapping (vRF) data
For identifying ROIs, we acquire retinotopic mapping scans using a protocol similar to that defined in [Mackey, Winawer & Curtis, 2017, *eLife*](https://elifesciences.org/articles/22974). Participants attend to a moving bar presented at different widths, moving steadily across the screen in one of four directions (top-to-bottom,left-to-right,bottom-to-top,right-to-left) and perform a challenging discrimination task requiring attention to the entire bar (stimulus scripts available [here](https://github.com/tommysprague/vRF_stim)). We repeat the same stimulus sequence 10-12x per participant and average over all scan timeseries, then estimate a receptive field for each voxel, using a GPU-accelerated branch of [*vistasoft*](https://github.com/tommysprague/vistasoft_ts/tree/sprague_gridfit_updates).

We acquire data at 2.0 mm isovoxel resolution with a 1200 ms TR (multiband factor 4x) on a Siemens Prisma scanner. We also acquire high-resolution anatomy (0.8 mm isovoxel T1's and T2), and spin-echo blip up/down 'TOPUP'-style fieldmaps to correct for field distortions. We analyze RF datasets in several ways, each used at different stages of analyses. For ROI identification, we smooth data along the surface. For using RF parameters to sort voxels or perform other (multivariate) analyses, we only project data onto surface and back into volume space. By performing RF fitting and subsequent analyses in volume space after surface-based smoothing, we ensure we do not oversample the data, which can have substantial impacts on multivariate analyses (especially those concerned with correlations between voxels). For completeness, we also fit RFs to 'raw' data (after pre-processing) that was never projected onto the surface and thus still includes subcortical voxels. These data may be used for future purposes, but can also provide a good test of functional/anatomical alignment (do well-fit functional voxels fall within cortical ribbon defined anatomically?)

The script __preproc_RF.sh__ calls all necessary preprocessing commands to set up a directory structure that can be analyzed with vistasoft:
1. __bias_correct.sh__ - adjusts image intensity to account for strong inhomogeneity resulting from 64 ch Siemens head/neck coil. This helps with image registration later on
2. __spatial_afni_proc_SEalign.sh__ - all spatial pre-processing steps, including:
  -  distortion-correction of spin-echo AP/PA images - these are then used as the 'targets' for alignment to anatomy and motion correction within a 'sub-session' (set of runs nearest in time to the spin-echo pair).
  -   distortion-correction, motion correction, alignment to anatomy, and projection onto surface + blurring. This uses afni_proc.py, which intelligently combines all transformation steps into a single resampling operation, minimizing smoothing incurred during preprocessing.
  -  projection back into volume space of all surface datasets
3. Preparation of vistasoft directory (averaging timeseries)
4. TODO: basic signal quality checks, like tSNR/COV, and computation of noise voxel masks


## Task data
When preprocessing task data (__preproc_task.sh__), we perform most of the above steps (though we leave out surface-smoothing), and add one other:
1. __temporal_task.sh__ - detrends data and converts to % signal change

Resulting data (both surface-ribbon, 'surf', and full-volume, 'func') can then be used by custom data processing scripts (typically in MATLAB/Python)

## Converting retinotopic mapping datasets to task data grid
We typically acquire retinotopic mapping datasets at higher resolution than task data to minimize partial voluming and clean up ROI definitions. Sometimes, we also want to use voxel RF (vRF) properties to filter/sort voxels in task data analyses. Accordingly, we need vRF parameters in the same grid as the task data. While in principle one could resample the best-fit RF volumes (RF*.nii.gz files created by vista), this won't be quite correct (especially the variance explained parameter, which is likely important for sorting voxels). Additionally, without re-adjusting the polar angle & eccentricity parameters after resampling given new x,y, those will be slightly incorrect.

So, instead, we'll resample the original datasets and re-fit models with vista. While computationally intensive, this is necessary to ensure accurate model parameters. At present, we resample only the raw 'func' files and the surface-projected 'surf' files, but not the surface-smoothed 'blur'/'ss5' files (those are used only for ROI definitions, but not sorting voxels based on vRF properties). For 'surf' files, rather than resampling the surf volume .nii.gz files, we'll re-project from surface .dset files into volume with **surf_to_vol_targGrid.sh** which allows for specification of a custom volume grid, which we derive from pre-processed task data (NOTE: this means task data must be pre-processed with **preproc_task.sh** before we can resample retinotopy). All resampled data is placed in _retinotopy_ session directory, and will need to be indexed as such from task datasets.

To resample retintopy data, see **RF_to_task.sh**, which:
1. resamples in volume the anat masks (surfant_brainmask*.nii.gz) to match new grid resolution
2. runs **surf_to_vol_targGrid.sh** on 'surf' files
3. resamples 'func' files
4. averages all runs of 'surf' and 'func' files into _vista/ directory

You'll still need to manually run do_RFs.m to recompute RF properties, but otherwise this script will take care of all data preparation.

## Dependencies
Some functions (surface-->volume) require repository https://github.com/tommysprague/preproc_mFiles, which requires vistasoft (ideally this branch: https://github.com/tommysprague/vistasoft_ts/tree/sprague_gridfit_updates)
