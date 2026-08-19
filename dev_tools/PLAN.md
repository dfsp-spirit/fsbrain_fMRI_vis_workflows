# fsbrain fMRI Showcase & Validation Suite: Project Plan

## 1. Project Objective & Vision
Demonstrate that fsbrain is a first-class visualization tool for functional MRI (fMRI) researchers by providing working, reproducible, and visually validated workflows for standard fMRI data types in pure R.

The repository serves two purposes:
1. Showcase / Tutorial: A web-rendered guide (Quarto/Rmd) showing fMRI researchers how to plot their statistical results.
2. Ground Truth Validation: Verifying that coordinate transformations, hemisphere alignments, and surface index mappings match established anatomical topographies.

---

## 2. Core Workflows & Datasets

### Workflow A: Volumetric MNI152 -> Surface Mesh (fsaverage)
* Use Case: Group-level GLMs and contrast maps generated in volumetric MNI152 space (standard SPM, FSL, or AFNI pipelines).
* Bridging Tool: regfusionr::vol_to_fsaverage() (Wu et al., 2018 Registration Fusion). Call it with `out_dir = NULL` to get the projected per-vertex data for both hemispheres in R directly.
* Test Dataset: MNI152 central sulcus probability map, BUNDLED with regfusionr (no download needed, no dead-URL risk): `system.file("extdata/testdata/MNI_probMap_ants.central_sulc.nii.gz", package="regfusionr")`. Ground truth is unambiguous: the peak maps to the central sulcus, immediately posterior to the precentral gyrus (motor cortex / hand-knob region).
  * NOTE: the previously planned "HCP Motor Task Group Contrast via NeuroVault (Image ID 23516)" was checked and is WRONG/dead: image 23516 is actually 'topic 71 fwhm=6' (collection 1459), collection 1806 is 'BrainPedia', and the filename tfMRI_MOTOR_level2_lh_hp200_s4.nii.gz does not exist anywhere. Do not use it. A real HCP motor contrast would be a CIFTI dscalar (32k fs_LR) rather than an MNI volume, so it belongs in Workflow B if desired.
* Template Space (IMPORTANT): regfusionr's `template_type` must match the actual space of the input image. The bundled central sulc map is MNI152, use `template_type='MNI152_orig'` (with `rf_type='RF_ANTs'`). For other input images, verify the header/space and test the MNI152 variants; a wrong `template_type` gives a slightly misregistered peak. This is exactly what the ground-truth check below is for.
* Ground Truth Validation Criteria:
  * Peak probability must map to the central sulcus (precentral gyrus posterior border / hand-knob region).
  * Postcentral or otherwise mislocated peaks indicate a wrong template_type, coordinate, or header flip.
  * Checked programmatically in run_mni_validation.R (not just visually).
* Optional Annotation Tool: brainloc for peak coordinate lookup and anatomical labeling.

### Workflow B: CIFTI Grayordinates -> Symmetric Mesh (fs_LR_32k)
* Use Case: Standard outputs from modern fMRI preprocessing pipelines (fMRIPrep, HCP Pipelines, ciftify) in CIFTI-2 format (.dscalar.nii / .dtseries.nii).
* Bridging Tool: freesurferformats::read.fs.morph.cifti() (PRIMARY; freesurferformats is already an fsbrain dependency and it uses the small 'cifti' package). It reconstructs a full 32,492-length per-vertex vector per hemisphere and sets medial-wall vertices to NA. ciftiTools is an optional alternative (it returns raw cortical arrays; you must place them into the mesh yourself using the CIFTI BrainModel indices).
* Test Dataset: ciftiTools bundled dscalar `Conte69.MyelinAndCorrThickness.32k_fs_LR.dscalar.nii` (Conte69 subject; 2 measures per vertex: myelin and cortical thickness; 32k fs_LR space - matches the meshes already in data/).
  * URL (raw GitHub master, VERIFIED live): https://raw.githubusercontent.com/mandymejia/ciftiTools/master/inst/extdata/Conte69.MyelinAndCorrThickness.32k_fs_LR.dscalar.nii
  * More robust: ciftiTools is on CRAN, so the file ships with the installed package: `system.file("extdata", "Conte69.MyelinAndCorrThickness.32k_fs_LR.dscalar.nii", package="ciftiTools")` - no URL, versioned with the package.
  * NOTE: the previously planned 'conte_sub.dscalar.nii' no longer exists in ciftiTools (renamed/removed); that URL was dead.
* Mesh Source: fs_LR 32k GIFTI surfaces (.surf.gii, 32,492 vertices per hemisphere) from ciftiTools, TemplateFlow (tpl-fsLR), or Diedrichsen Lab GitHub. Already present in 02_cifti_fslr32k/data/ (DiedrichsenLab fs_LR_32).
* Vertex Model (IMPORTANT): a CIFTI-2 file does NOT contain 32,492 values per hemisphere. The cortical arrays hold only the valid-cortex values: 29,657 (left) and 29,755 (right) - the fs_LR 32k meshes have 32,492 vertices per hemisphere INCLUDING the medial wall (2,835 / 2,737 medial-wall vertices). The CIFTI BrainModel block lists the surface vertex index for each value; these indices scatter the ~29.6k values into the 32,492-vertex mesh, and all remaining vertices are NA. fsbrain needs the full 32,492-length vector (medial wall = NA), which read.fs.morph.cifti() returns directly.
* Ground Truth Validation Criteria:
  * Cortical values land at the BrainModel vertex indices inside the 32,492-vertex mesh per hemisphere; no index shifting or inverted polar coordinates.
  * Medial wall vertices carry no value (NA) and are masked in the render.
  * Anatomical check: an HCP motor task contrast peaks in the precentral hand-knob region (checked programmatically in run_cifti_validation.R).

---

## 3. Repository Architecture

```text
fsbrain-fmri-showcase/
|-- README.md                      # Overview, rendered gallery snapshots, quickstart links
|-- PLAN.md                        # This roadmap document
|-- _quarto.yml                    # Quarto website configuration
|-- index.qmd                      # Landing page & pipeline conceptual comparison
|
|-- 01_mni_volumetric/             # Workflow A
|   |-- workflow_mni.qmd           # Step-by-step tutorial with code and rendered views
|   |-- run_mni_pipeline.R         # Standalone, runnable CLI script (mapping + rendering)
|   |-- run_mni_validation.R       # Automated ground-truth check (peak label assertion)
|   `-- get_data.R                 # Download helper for NeuroVault MNI volume
|
|-- 02_cifti_fslr32k/              # Workflow B
|   |-- workflow_cifti.qmd         # Step-by-step tutorial for CIFTI & fs_LR_32k
|   |-- run_cifti_pipeline.R       # Standalone, runnable CLI script (mapping + rendering)
|   |-- run_cifti_validation.R     # Automated ground-truth check (peak label assertion)
|   `-- data/                      # fs_LR 32k GIFTI meshes + Yeo labels (already present)
|
|-- .github/
|   `-- workflows/
|       `-- publish.yml            # CI/CD: build Quarto site and publish to GitHub Pages
`-- renv.lock                      # Locked dependencies for reproducible execution
```

---

## 4. Implementation Steps

### Phase 1: Data Access & Caching Scripts
- [ ] Implement download_if_missing() utility in R to download sample data from NeuroVault and raw GitHub endpoints on demand (avoid committing large binary data to git).
- [ ] Verify the downloaded NeuroVault image space: check the NIFTI header/affine to determine whether it is 'MNI152_orig' or 'MNI152_norm' space (sets the regfusionr::vol_to_fsaverage() `template_type`).
- [ ] Verify the fs_LR 32k GIFTI surface vertex counts (V = 32,492 per hemisphere). NOTE: inflated meshes + sulc/Yeo label files are already present in 02_cifti_fslr32k/data/ (DiedrichsenLab fs_LR_32); confirm they match the HCP/CIFTI fs_LR standard space.

### Phase 2: Workflow Scripting & Core Logic
- [ ] Script 1 (run_mni_pipeline.R):
  - No download needed: use the regfusionr-bundled volume via system.file() (MNI_probMap_ants.central_sulc.nii.gz).
  - Execute regfusionr::vol_to_fsaverage(input_img, template_type = 'MNI152_orig', rf_type = 'RF_ANTs', out_dir = NULL) to get per-vertex data for 'lh' and 'rh' in R.
  - Render with fsbrain::vis.data.on.subject() (sequential colormap; threshold the probability map, e.g. prob > 0.5, map_to_NA = 0) on fsaverage (fsbrain::download_fsaverage()).
  - Export multi-angle static PNG figures (lateral, medial, dorsal) via fsbrain::export() / vislayout.from.coloredmeshes().
- [ ] Script 1b (run_mni_validation.R): AUTOMATED ground-truth check - find the peak probability vertex and assert it sits on the central sulcus (bordering the precentral gyrus / hand-knob region); report label + distance. Makes the 'ground truth validation' reproducible instead of visual-only.
- [ ] Script 2 (run_cifti_pipeline.R):
  - Read the Conte69 dscalar with freesurferformats::read.fs.morph.cifti() for 'lh' and 'rh' (returns 32,492-length vectors, medial wall = NA). The file has 2 measures; select cortical thickness with data_column = 2L (myelin is column 1).
  - Render onto the fs_LR_32k GIFTI surfaces via the preloaded-mesh path: coloredmesh.from.preloaded.data() + vislayout.from.coloredmeshes() / fsbrain::export(). (fs_LR 32k is not a FreeSurfer subject dir, so vis.data.on.subject() is not the right entry point here.)
  - Verify medial wall masking (no values on medial wall vertices).
- [ ] Script 2b (run_cifti_validation.R): AUTOMATED ground-truth check - locate the peak vertex in the 32k mesh and confirm it is in the precentral/sensorimotor region (use the Yeo 7-network label files already in 02_cifti_fslr32k/data/, or an fs_LR aparc if added).

### Phase 3: Quarto / R Markdown Showcase
- [ ] Write 01_mni_volumetric/workflow_mni.qmd:
  - Context: Why volume-to-surface mapping matters in fMRI.
  - Explanation of Registration Fusion (regfusionr).
  - Code block + embedded high-res rendered figures.
  - Anatomical validation breakdown (confirming central sulcus / motor hand-knob region) - include output of run_mni_validation.R.
- [ ] Write 02_cifti_fslr32k/workflow_cifti.qmd:
  - Context: The shift from fsaverage to fs_LR 32k grayordinates in HCP/fMRIPrep.
  - Working with GIFTI meshes and CIFTI scalar vectors (vertex model: 29,657/29,755 values -> 32,492-vertex mesh via BrainModel indices; medial wall = NA).
  - Code block + embedded high-res rendered figures.
  - Medial wall / vertex-mapping validation - include output of run_cifti_validation.R.

### Phase 4: CI/CD & Publication
- [ ] Configure _quarto.yml for website generation.
- [ ] Set up GitHub Actions workflow to build and push rendered HTML to GitHub Pages.
- [ ] Link live demo from fsbrain main repository README.

### Rendering / CI status (IMPORTANT - current fsbrain version)
- Figures are rendered with the CURRENT fsbrain default backend (rgl + magick for image merge). This requires a working display / OpenGL on the rendering machine, so:
  - Render the figures on a workstation (interactive R with a display) and commit the PNGs, or run the pipeline on a machine with X/OpenGL.
  - For now, CI only builds the Quarto site and publishes it; it does NOT render the brain figures headlessly yet. Showing how the workflows work matters more than CI rendering at this stage.
- The scimesh software renderer (GPU-free, headless, CPU-only) is the planned future backend that will make rendering work in CI: fsbrain feature branch 'feature/scimesh-backend' adds `options(fsbrain.renderer_backend = "scimesh")` for static PNG output. scimesh is not on CRAN yet (submission in progress; R CMD check passes), so it is installed from GitHub for now. Once the fsbrain integration lands and scimesh is on CRAN, Phase 4 CI will render the full site headlessly. This plan is updated at that point.

---

## 5. Required R Dependencies
* fsbrain (current version: rgl default renderer + `fsbrain.renderer_backend` option)
* freesurferformats (provides read.fs.morph.cifti() for CIFTI cortex extraction; already an fsbrain dependency)
* cifti (required by freesurferformats::read.fs.morph.cifti())
* regfusionr (recommend `oce` for interpolation)
* brainloc (optional, peak coordinate lookup)
* ciftiTools (optional alternative CIFTI reader)
* gifti
* rgl (current rendering backend; needs display/OpenGL)
* magick (required by the current image export/merge path)
* scimesh (future headless renderer backend; not on CRAN yet, install from GitHub)
* Quarto / Pandoc (site rendering; not R packages but required)
