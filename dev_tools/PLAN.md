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
* Bridging Tool: regfusionr::vol_to_fsaverage() (Wu et al., 2018 Registration Fusion).
* Test Dataset: HCP Motor Task Group Contrast (Left Hand > Baseline) via NeuroVault (Image ID: 23516).
  * URL: https://neurovault.org/media/images/1806/tfMRI_MOTOR_level2_lh_hp200_s4.nii.gz
* Ground Truth Validation Criteria:
  * Primary activation must map strictly to the right precentral gyrus (motor hand knob / Desikan-Killiany precentral label) and supplementary motor area (SMA).
  * Postcentral or ipsilateral (left) dominance indicates a coordinate or header flip.
* Optional Annotation Tool: brainloc for peak coordinate lookup and anatomical labeling.

### Workflow B: CIFTI Grayordinates -> Symmetric Mesh (fs_LR_32k)
* Use Case: Standard outputs from modern fMRI preprocessing pipelines (fMRIPrep, HCP Pipelines, ciftify) in CIFTI-2 format (.dscalar.nii / .dtseries.nii).
* Bridging Tool: ciftiTools (or manual GIFTI reading via freesurferformats).
* Test Dataset: Standard HCP task contrast or ciftiTools bundled validation dscalar (conte_sub.dscalar.nii / tfMRI_MOTOR_hp200_s2_level2.dscalar.nii).
  * URL (Sample): https://github.com/mandymejia/ciftiTools/raw/master/inst/extdata/conte_sub.dscalar.nii
* Mesh Source: fs_LR 32k GIFTI surfaces (.surf.gii, 32,492 vertices per hemisphere) from ciftiTools, TemplateFlow (tpl-fsLR), or Diedrichsen Lab GitHub.
* Ground Truth Validation Criteria:
  * Cortex left and right data arrays align exactly to 32,492 vertices.
  * Medial wall boundaries match without index shifting or inverted polar coordinates.

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
|   |-- run_mni_pipeline.R         # Standalone, runnable CLI script
|   `-- get_data.R                 # Download helper for NeuroVault MNI volume
|
|-- 02_cifti_fslr32k/              # Workflow B
|   |-- workflow_cifti.qmd         # Step-by-step tutorial for CIFTI & fs_LR_32k
|   |-- run_cifti_pipeline.R       # Standalone, runnable CLI script
|   `-- data/                      # Bundled or scripted download for fs_LR 32k GIFTI meshes
|
|-- .github/
|   `-- workflows/
|       `-- publish.yml            # CI/CD: render Quarto to GitHub Pages automatically
`-- renv.lock                      # Locked dependencies for reproducible execution
```

---

## 4. Implementation Steps

### Phase 1: Data Access & Caching Scripts
- [ ] Implement download_if_missing() utility in R to download sample data from NeuroVault and raw GitHub endpoints on demand (avoid committing large binary data to git).
- [ ] Acquire tpl-fsLR_hemi-{L,R}_den-32k_inflated.surf.gii and verify vertex counts (V = 32,492).

### Phase 2: Workflow Scripting & Core Logic
- [ ] Script 1 (run_mni_pipeline.R):
  - Download NeuroVault image.
  - Execute regfusionr::vol_to_fsaverage().
  - Render with fsbrain::vis.data.on.subject() using two-tailed symmetric thresholding (e.g., |t| > 3.1).
  - Export multi-angle static PNG figures (lateral, medial, dorsal).
- [ ] Script 2 (run_cifti_pipeline.R):
  - Read sample CIFTI .dscalar.nii.
  - Extract left and right cortical arrays.
  - Render directly onto fs_LR_32k GIFTI surfaces.
  - Verify medial wall masking.

### Phase 3: Quarto / R Markdown Showcase
- [ ] Write 01_mni_volumetric/workflow_mni.qmd:
  - Context: Why volume-to-surface mapping matters in fMRI.
  - Explanation of Registration Fusion (regfusionr).
  - Code block + embedded high-res rendered figures.
  - Anatomical validation breakdown (confirming right motor hand knob).
- [ ] Write 02_cifti_fslr32k/workflow_cifti.qmd:
  - Context: The shift from fsaverage to fs_LR 32k grayordinates in HCP/fMRIPrep.
  - Working with GIFTI meshes and CIFTI scalar vectors.
  - Code block + embedded high-res rendered figures.

### Phase 4: CI/CD & Publication
- [ ] Configure _quarto.yml for website generation.
- [ ] Set up GitHub Actions workflow to build and push rendered HTML to GitHub Pages.
- [ ] Link live demo from fsbrain main repository README.

---

## 5. Required R Dependencies
* fsbrain
* freesurferformats
* regfusionr
* brainloc
* ciftiTools
* gifti
* rgl
