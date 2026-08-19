#!/usr/bin/env Rscript
#
# Workflow B: automated ground-truth validation.
#
# Checks:
#   1. Mapping correctness: the CIFTI cortical arrays are placed at the CIFTI
#      BrainModel vertex indices inside the 32,492-vertex fs_LR 32k meshes, with
#      the medial wall masked to NA. The total number of cortical vertices
#      (L + R) must equal the standard fs_LR 32k count (59,412). Any index
#      shifting or polar inversion would break these counts.
#   2. Anatomical sanity: the peak of the cortical-thickness map must land in
#      the thickest-cortex region (temporal pole / medial temporal cortex =
#      Yeo 7-network 'Limbic' network, key 5).
#
# Exits 0 on PASS, 1 on FAIL (so it can gate CI later).
#
# Usage: Rscript run_cifti_validation.R   (run from the repository root)
# Requires: fsbrain, freesurferformats, gifti.

suppressMessages({
    library(fsbrain)
    library(freesurferformats)
    library(gifti)
})

# --- locate this script's directory (robust to cwd) -----------------------------
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
workflow_dir <- if (length(file_arg)) dirname(normalizePath(file_arg)) else getwd()
data_dir <- file.path(workflow_dir, "data")

dscalar_file <- file.path(data_dir, "fs_LR.32k.LR.thickness.dscalar.nii")
expected_total_cortical <- 59412L   # standard fs_LR 32k cortical grayordinates (L + R)
expected_peak_network   <- 5L       # Yeo 7-network: 5 = Limbic (temporal pole region)

# --- read data -----------------------------------------------------------------
th <- list(
    lh = freesurferformats::read.fs.morph.cifti(dscalar_file, "lh"),
    rh = freesurferformats::read.fs.morph.cifti(dscalar_file, "rh")
)
sf <- list(
    lh = freesurferformats::read.fs.surface(file.path(data_dir, "fs_LR.32k.L.inflated.surf.gii")),
    rh = freesurferformats::read.fs.surface(file.path(data_dir, "fs_LR.32k.R.inflated.surf.gii"))
)
yeo <- list(
    lh = gifti::readgii(file.path(data_dir, "Yeo_JNeurophysiol11_7Networks.32k.L.label.gii")),
    rh = gifti::readgii(file.path(data_dir, "Yeo_JNeurophysiol11_7Networks.32k.R.label.gii"))
)

# --- 1. mapping checks -----------------------------------------------------------
all_ok <- TRUE
for (h in c("lh", "rh")) {
    len_ok <- length(th[[h]]) == nrow(sf[[h]]$vertices)
    all_ok <- all_ok && len_ok
    cat(sprintf("  %s: data length %d == mesh vertices %d  [%s]\n",
                h, length(th[[h]]), nrow(sf[[h]]$vertices), ifelse(len_ok, "PASS", "FAIL")))
}
total_cortical <- sum(!is.na(th$lh)) + sum(!is.na(th$rh))
count_ok <- total_cortical == expected_total_cortical
all_ok <- all_ok && count_ok
cat(sprintf("  total cortical vertices (L+R): %d == expected %d  [%s]\n",
            total_cortical, expected_total_cortical, ifelse(count_ok, "PASS", "FAIL")))

# --- 2. anatomical sanity: peak thickness -> Yeo network ---------------------------
for (h in c("lh", "rh")) {
    H     <- toupper(substr(h, 1, 1))
    yl    <- as.integer(yeo[[h]]$data[[1]])
    yt    <- yeo[[h]]$label                      # matrix, rownames = network names
    pk    <- which.max(th[[h]])
    netkey <- yl[pk]
    nm     <- if (netkey == 0L) "medial wall / unassigned" else
              rownames(yt)[match(as.character(netkey), as.character(yt[, "Key"]))]
    ok    <- netkey == expected_peak_network
    all_ok <- all_ok && ok
    cat(sprintf("  %s: peak thickness %.3f mm at vertex %d -> Yeo network key %d ('%s')  [%s]\n",
                h, th[[h]][pk], pk, netkey, nm, ifelse(ok, "PASS", "FAIL")))
}

if (all_ok) {
    cat("Workflow B validation PASSED.\n")
    quit(status = 0)
} else {
    cat("Workflow B validation FAILED.\n")
    quit(status = 1)
}
