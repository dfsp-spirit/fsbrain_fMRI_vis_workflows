#!/usr/bin/env Rscript
#
# Workflow A: automated ground-truth validation.
#
# The MNI152 central sulcus probability map, when correctly mapped to fsaverage,
# must peak ON the central sulcus - i.e. on the precentral gyrus (posterior bank)
# or the postcentral gyrus (anterior bank) in the Desikan-Killiany atlas.
# A peak anywhere else indicates a wrong template_type, a coordinate/header flip,
# or an index-shifting bug.
#
# Exits 0 on PASS, 1 on FAIL (so it can gate CI later).
#
# Usage: Rscript run_mni_validation.R   (run from the repository root)
# Requires: fsbrain, regfusionr, freesurferformats, fsaverage via SUBJECTS_DIR.

suppressMessages({
    library(fsbrain)
    library(freesurferformats)
    library(regfusionr)
})

# --- parameters ----------------------------------------------------------------
subjects_dir   <- Sys.getenv("SUBJECTS_DIR")
subject_id     <- "fsaverage"
template_type  <- "MNI152_orig"
rf_type        <- "RF_ANTs"
allowed_labels <- c("precentral", "postcentral", "paracentral")  # flank the central sulcus

if (subjects_dir == "") stop("Environment variable SUBJECTS_DIR is not set. See get_data.R.")

# --- map volume -> fsaverage ----------------------------------------------------
probmap_file <- system.file("extdata/testdata", "MNI_probMap_ants.central_sulc.nii.gz",
                            package = "regfusionr")
mapped <- regfusionr::vol_to_fsaverage(probmap_file,
                                       template_type = template_type,
                                       rf_type       = rf_type,
                                       out_dir       = NULL)

# --- check the peak label per hemisphere -----------------------------------------
all_ok <- TRUE
for (h in c("lh", "rh")) {
    v    <- mapped[[h]]
    pk   <- which.max(v)
    annot <- freesurferformats::read.fs.annot(file.path(subjects_dir, subject_id,
                                                        "label", sprintf("%s.aparc.annot", h)))
    label <- annot$label_names[pk]
    ok    <- label %in% allowed_labels
    all_ok <- all_ok && ok
    cat(sprintf("  %s: peak P(central sulcus)=%.3f at vertex %d -> DK label '%s'  [%s]\n",
                h, v[pk], pk, label, ifelse(ok, "PASS", "FAIL")))
}

if (all_ok) {
    cat("Workflow A validation PASSED.\n")
    quit(status = 0)
} else {
    cat("Workflow A validation FAILED.\n")
    quit(status = 1)
}
