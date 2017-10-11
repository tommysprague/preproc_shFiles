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
5. TODO: projection into a 'target' volume space (likely via a separate function) - for projecting high-resolution data, from retinotopy, into lower-resolution grids used for task


## Task data
When preprocessing task data (__preproc_task.sh__), we perform most of the above steps (though we leave out surface-smoothing), and add one other:
1. __temporal_task.sh__ - detrends data and converts to % signal change

Resulting data (both surface-ribbon, 'surf', and full-volume, 'func') can then be used by custom data processing scripts (typically in MATLAB/Python)

Some functions (surface-->volume) require repository https://github.com/tommysprague/preproc_mFiles, which requires vistasoft (ideally this branch: https://github.com/tommysprague/vistasoft_ts/tree/sprague_gridfit_updates)
