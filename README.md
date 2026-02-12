# Geopotential Artifacts Generator

Artifact repository for Geopotential.jl 
Generate optimized binary artifacts from geopotential coefficient text files.

## Quick Start

1. **Install dependencies:**
   ```bash
   julia --project -e "using Pkg; Pkg.instantiate()"
   ```

2. **Download coefficient files** to the `tmp/` directory:
   - EGM2008.gfc
   - EGM96.gfc
   - gggrx_1200a_sha.tab
   - gmm3_120_sha.tab

3. **Run tests:**
   ```bash
   julia --project test_units.jl
   ```

4. **Generate artifacts:**
   ```bash
   julia --project test_generation.jl EGM2008 tmp/EGM2008.gfc
   ```

## Output Structure

```
GeopotentialArtifacts/
├── bin/                # Binary coefficient files
│   ├── EGM2008.bin
│   ├── EGM2008_metadata.txt
│   └── ...
└── tarballs/           # Single bundled artifact
   └── geopotential_bins.tar.gz
```

## Supported Models

- **EGM2008** - Earth (degree 2190)
- **EGM96** - Earth (degree 360)
- **GRGM1200A** - Moon (degree 1200)
- **GMM3** - Mars (degree 120, static field only)

## Binary Format

Each `.bin` file contains:
- 4 bytes: `Int32` l_max
- 4 bytes: `Int32` m_max
- 8 bytes: `Float64` gravitational parameter (GM)
- 8 bytes: `Float64` reference radius (R_ref)
- (l_max+1)×(m_max+1)×8 bytes: C coefficients (Float64, column-major)
- (l_max+1)×(m_max+1)×8 bytes: S coefficients (Float64, column-major)

Indexing: `C[l+1, m+1]`, `S[l+1, m+1]` (1-based)

## Notes

- All artifacts contain **static fields only**
- Time-varying components (e.g., Mars seasonal variations) are not included
- Binary format is little-endian
- The bundled tarball includes the full `bin/` folder

## Adding New Models, Bundling, and Releasing

### 1) Add a new model

1. **Add metadata** in `src/model_metadata.toml`:
   - Add a new `[MODEL_ID]` section with:
     - `name`, `full_name`, `source_url`, `gravitational_parameter`, `reference_radius`
     - `l_max`, `m_max`, `normalized`, `description`, `provider`, `license`, `citation`, etc.
     - `coeff_filename` and `coeff_start_line` for parsing
2. **Choose parser** (update if needed):
   - ICGEM (`.gfc`) for Earth models → add to EGM2008/EGM96 start line 22
   - PGDA (`.tab`) for Moon/Mars models → add to GRGM1200A/GMM3 start line 2
   - Update `read_coeff_file(...)` in `src/gen artifacts.jl` if a new format is needed.

### 2) Generate binaries + bundle tarball

1. Add the new coefficient file into `tmp/` (or let the generator download it if acessible via HTTP).
2. Run the generator for all models (recommended):
   ```bash
   julia --project src/main.jl all
   ```
   This produces:
   - `bin/<MODEL>.bin`
   - `bin/<MODEL>_metadata.txt`
   - `bin/models.json`
   - `tarballs/geopotential_bins.tar.gz`

   Or run for a specific model:
   ```bash
   julia --project src/main.jl <MODEL_NAME>
   ```

### 4) Create or replace the GitHub release

This repo uses GitHub Releases to distribute the bundled artifact.

1. Generate new release notes:
   ```bash
   julia --project src/gen_release_notes.jl ./release_notes.md
   ```
2. Create or replace the release (example for v1.0.0):
   ```bash
   gh release create v1.0.0 tarballs/geopotential_bins.tar.gz \
     -t "Geopotential Models v1.0.0" -F release_notes.md
   ```

> If you need to replace an existing release, you can delete the old release and its tag first:
```bash
gh release delete v1.0.0 -y
git tag -d v1.0.0
```
