# compute tSNR/COV
#
# TODO: figure out all the filenames on input side! those come from spatial_afni_proc.py, and any surface smoothing afterwards

# right now, assumes RF data, so just remove average across runs
# FUTURE: allow for specification of trial events, so these can be regressed out

# 1) take mean of each run (result: single volume)


# 2) detrend each run


# 3) mean over all detrended runs



# 4) remove result of [3] from each of [2], add back in [1]



# 5) concatenate all of [4] - this is all residuals



# 6) compute standard deviation and mean of residuals across all runs, save these out 


# 7) save out a "signal quality" nii.gz with tSNR (mean/std dev) and COV (std dev/mean)
