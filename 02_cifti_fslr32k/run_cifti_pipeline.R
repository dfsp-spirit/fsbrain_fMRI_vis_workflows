#!/usr/bin/env Rscript
#
# Workflow B: CIFTI Grayordinates -> fs_LR 32k Surface
#
# Reads a CIFTI-2 dscalar (cortical thickness, DiedrichsenLab fs_LR_32 - same
# source as the meshes in data/) and renders it onto the fs_LR 32k GIFTI
# surfaces with fsbrain, using the preloaded-mesh path (fs_LR 32k is not a
# FreeSurfer subject dir, so vis.data.on.subject() is not the entry point).
#
# The CIFTI cortical arrays only hold the valid-cortex vertices (29,696 / 29,716
# here); read.fs.morph.cifti() places them at the CIFTI BrainModel vertex
# indices inside the 32,492-vertex meshes and sets the medial wall to NA.
#
# Usage: Rscript run_cifti_pipeline.R   (run from the repository root)
# Requires: fsbrain, freesurferformats (which uses the 'cifti' package), magick.

suppressMessages({
    library(fsbrain)
    library(freesurferformats)
})

# --- locate this script's directory (robust to cwd) -----------------------------
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
workflow_dir <- if (length(file_arg)) dirname(normalizePath(file_arg)) else getwd()
data_dir <- file.path(workflow_dir, "data")
fig_dir  <- file.path(workflow_dir, "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# --- parameters -----------------------------------------------------------------
dscalar_file <- file.path(data_dir, "fs_LR.32k.LR.thickness.dscalar.nii")  # cortical thickness (mm)
surf_lh_file <- file.path(data_dir, "fs_LR.32k.L.inflated.surf.gii")
surf_rh_file <- file.path(data_dir, "fs_LR.32k.R.inflated.surf.gii")
data_column  <- 1L
view_angles  <- fsbrain::get.view.angle.names(angle_set = "t4")

for (f in c(dscalar_file, surf_lh_file, surf_rh_file)) {
    if (!file.exists(f)) stop(sprintf("Missing data file: %s", f))
}

# --- 1. read CIFTI -> per-vertex data (medial wall becomes NA) --------------------
cat("Reading CIFTI dscalar (cortical thickness)...\n")
th_lh <- freesurferformats::read.fs.morph.cifti(dscalar_file, "lh", data_column = data_column)
th_rh <- freesurferformats::read.fs.morph.cifti(dscalar_file, "rh", data_column = data_column)

# --- 2. read fs_LR 32k meshes -----------------------------------------------------
sf_lh <- freesurferformats::read.fs.surface(surf_lh_file)
sf_rh <- freesurferformats::read.fs.surface(surf_rh_file)

# --- 3. sanity checks ----------------------------------------------------------------
stopifnot(length(th_lh) == nrow(sf_lh$vertices), length(th_rh) == nrow(sf_rh$vertices))
cat(sprintf("  lh: %d/%d vertices have data, %d medial-wall NA\n",
            sum(!is.na(th_lh)), length(th_lh), sum(is.na(th_lh))))
cat(sprintf("  rh: %d/%d vertices have data, %d medial-wall NA\n",
            sum(!is.na(th_rh)), length(th_rh), sum(is.na(th_rh))))

# --- 4. build coloredmeshes (preloaded-mesh path) ------------------------------------
cm_lh <- fsbrain::coloredmesh.from.preloaded.data(sf_lh, morph_data = th_lh, hemi = "lh")
cm_rh <- fsbrain::coloredmesh.from.preloaded.data(sf_rh, morph_data = th_rh, hemi = "rh")
coloredmeshes <- list("lh" = cm_lh, "rh" = cm_rh)

# --- 5. interactive view (only when running interactively with a display) -------------
if (interactive() && nzchar(Sys.getenv("DISPLAY"))) {
    cat("Opening interactive rgl view (close the window to continue)...\n")
    fsbrain::vis.coloredmeshes(coloredmeshes, draw_colorbar = TRUE)
}

# --- 6. static multi-view export --------------------------------------------------------
out_png <- file.path(fig_dir, "cifti_thickness_t4.png")
cat(sprintf("Exporting static figure to %s ...\n", out_png))
fsbrain::export(coloredmeshes,
                colorbar_legend = "Cortical thickness (mm)",
                output_img      = out_png,
                view_angles     = view_angles,
                silent          = FALSE)
cat(sprintf("Workflow B done. Figure: %s\n", out_png))
