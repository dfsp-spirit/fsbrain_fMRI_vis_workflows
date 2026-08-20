# fsbrain_fMRI_vis_workflows

R apps demonstrating fMRI visualization workflows using [fsbrain](https://github.com/dfsp-spirit/fsbrain). See `dev_tools/PLAN.md` for the full project plan.

Two workflows, each with a standalone pipeline script and an automated ground-truth validation script:

| Workflow | Pipeline | Validation |
|---|---|---|
| **A**: Volumetric MNI152 → fsaverage (regfusionr) | `01_mni_volumetric/run_mni_pipeline.R` | `01_mni_volumetric/run_mni_validation.R` |
| **B**: CIFTI grayordinates → fs_LR 32k (freesurferformats) | `02_cifti_fslr32k/run_cifti_pipeline.R` | `02_cifti_fslr32k/run_cifti_validation.R` |


** Browse the R markdown documents online **

[dfsp-spirit.github.io/fsbrain_fMRI_vis_workflows/](https://dfsp-spirit.github.io/fsbrain_fMRI_vis_workflows/)





## Reproducing / Building on your local computer

This is not optional.


### Requirements

- R ≥ 4.x, plus `fsbrain`, `freesurferformats`, `regfusionr`, `cifti`, `magick`, `rgl`, `gifti` (and `oce`, recommended by regfusionr).
- Workflow A needs a FreeSurfer install with **fsaverage** (the `SUBJECTS_DIR` env var must point at a subjects dir containing `fsaverage`). See `01_mni_volumetric/get_data.R`.
- Rendering currently uses the fsbrain default backend (rgl + magick), so a display/OpenGL is required to produce the PNGs.

### Quickstart

Run from the repository root:

```sh
# Workflow A: map the regfusionr-bundled MNI central-sulcus map to fsaverage and render
Rscript 01_mni_volumetric/run_mni_pipeline.R
# ... and verify the peak lands on the central sulcus / precentral gyrus
Rscript 01_mni_volumetric/run_mni_validation.R

# Workflow B: render CIFTI cortical thickness onto the fs_LR 32k meshes
Rscript 02_cifti_fslr32k/run_cifti_pipeline.R
# ... and verify the vertex mapping + anatomical peak
Rscript 02_cifti_fslr32k/run_cifti_validation.R
```

Figures are written to `01_mni_volumetric/figures/` and `02_cifti_fslr32k/figures/`.
