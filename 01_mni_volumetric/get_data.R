#!/usr/bin/env Rscript
#
# Workflow A: data access / verification helper.
#
# Workflow A needs two inputs:
#   1. The MNI152 central sulcus probability map - BUNDLED with the regfusionr
#      package, so there is nothing to download (it is the canonical regfusionr
#      example volume).
#   2. The fsaverage subject - taken from an existing FreeSurfer install via the
#      SUBJECTS_DIR environment variable. If it is missing, this script offers
#      to download it with fsbrain::download_fsaverage().
#
# Usage: Rscript get_data.R

suppressMessages({
    library(fsbrain)
    library(regfusionr)
})

# --- 1. MNI volume (bundled with regfusionr) ---------------------------------
probmap_file <- system.file("extdata/testdata", "MNI_probMap_ants.central_sulc.nii.gz",
                            package = "regfusionr")
if (!nzchar(probmap_file) || !file.exists(probmap_file)) {
    stop("Bundled MNI central sulcus probability map not found in regfusionr. Is regfusionr installed?")
}
cat(sprintf("MNI volume OK: %s\n", probmap_file))

# --- 2. fsaverage subject ----------------------------------------------------
subjects_dir <- Sys.getenv("SUBJECTS_DIR")
subject_id <- "fsaverage"
if (subjects_dir == "") {
    stop("Environment variable SUBJECTS_DIR is not set. Point it at a FreeSurfer subjects directory, e.g. export SUBJECTS_DIR=$FREESURFER_HOME/subjects")
}
if (!dir.exists(file.path(subjects_dir, subject_id))) {
    cat(sprintf("Subject '%s' not found in '%s'.\n", subject_id, subjects_dir))
    ans <- readline("Download fsaverage to this subjects dir? [y/N] ")
    if (tolower(trimws(ans)) == "y") {
        fsbrain::download_fsaverage(save_dir = subjects_dir)
    } else {
        stop("fsaverage is required. Aborting.")
    }
}
cat(sprintf("fsaverage OK: %s\n", file.path(subjects_dir, subject_id)))
cat("All Workflow A data is available.\n")
