#!/usr/bin/env Rscript
#
# Workflow A: Volumetric MNI152 -> Surface Mesh (fsaverage)
#
# Maps the MNI152 central sulcus probability map (bundled with regfusionr,
# Wu et al. 2018 Registration Fusion) to the fsaverage surface and renders it
# with fsbrain. The central sulcus is the posterior border of the precentral
# gyrus (motor cortex), so the mapped peak must land on precentral gyrus --
# see run_mni_validation.R for the automated ground-truth check.
#
# Usage: Rscript run_mni_pipeline.R   (run from the repository root)
# Requires: fsbrain, regfusionr, freesurferformats, and a FreeSurfer install
#           with fsaverage (SUBJECTS_DIR env var set). A display is needed for
#           the interactive rgl view; the static export also uses rgl + magick.

suppressMessages({
    library(fsbrain)
    library(freesurferformats)
    library(regfusionr)
})

# --- locate this script's directory (robust to cwd) ---------------------------
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
workflow_dir <- if (length(file_arg)) dirname(normalizePath(file_arg)) else getwd()
fig_dir <- file.path(workflow_dir, "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# --- parameters ---------------------------------------------------------------
subjects_dir <- Sys.getenv("SUBJECTS_DIR")
subject_id   <- "fsaverage"
template_type <- "MNI152_orig"   # space of the bundled input volume
rf_type       <- "RF_ANTs"       # Registration Fusion variant
threshold     <- 0.5             # show only vertices with P(central sulcus) > threshold
surface       <- "inflated"
view_angles   <- fsbrain::get.view.angle.names(angle_set = "t4")  # lateral + medial, both hemis

if (subjects_dir == "") {
    stop("Environment variable SUBJECTS_DIR is not set. See get_data.R.")
}
if (!dir.exists(file.path(subjects_dir, subject_id))) {
    stop(sprintf("Subject '%s' not found in '%s'. See get_data.R.", subject_id, subjects_dir))
}

# --- 1. volume -> fsaverage ----------------------------------------------------
probmap_file <- system.file("extdata/testdata", "MNI_probMap_ants.central_sulc.nii.gz",
                            package = "regfusionr")
cat(sprintf("Mapping %s to fsaverage (%s, %s) ...\n",
            basename(probmap_file), template_type, rf_type))
mapped <- regfusionr::vol_to_fsaverage(probmap_file,
                                       template_type = template_type,
                                       rf_type       = rf_type,
                                       out_dir       = NULL)   # return per-vertex data in R
cat(sprintf("  mapped: lh=%d vertices, rh=%d vertices, range=%.3f..%.3f\n",
            length(mapped$lh), length(mapped$rh),
            min(mapped$lh), max(mapped$lh)))

# --- 2. threshold the probability map ------------------------------------------
mapped$lh[mapped$lh < threshold] <- NA
mapped$rh[mapped$rh < threshold] <- NA

# --- 3. interactive view (only when running interactively with a display) ------
if (interactive() && nzchar(Sys.getenv("DISPLAY"))) {
    cat("Opening interactive rgl view (close the window to continue)...\n")
    fsbrain::vis.data.on.subject(subjects_dir, subject_id,
                                 morph_data_lh = mapped$lh,
                                 morph_data_rh = mapped$rh,
                                 surface = surface,
                                 views = c("t4"),
                                 draw_colorbar = TRUE,
                                 bg = "sulc")
}

# --- 4. build coloredmeshes and export a static multi-view figure --------------
cat("Building coloredmeshes ...\n")
cm <- fsbrain::vis.data.on.subject(subjects_dir, subject_id,
                                   morph_data_lh = mapped$lh,
                                   morph_data_rh = mapped$rh,
                                   surface = surface,
                                   views = NULL,                       # do not render now
                                   rglactions = list("no_vis" = TRUE), # (also suppresses rendering)
                                   draw_colorbar = FALSE)
out_png <- file.path(fig_dir, "mni_central_sulc_t4.png")
cat(sprintf("Exporting static figure to %s ...\n", out_png))
fsbrain::export(cm,
                colorbar_legend = "P(central sulcus)",
                output_img      = out_png,
                view_angles     = view_angles,
                silent          = FALSE)
cat(sprintf("Workflow A done. Figure: %s\n", out_png))
