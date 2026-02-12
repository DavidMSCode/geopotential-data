# Geopotential Artifacts Generator

Generate optimized binary artifacts from geopotential coefficient text files.

## Quick Start

1. **Install dependencies:**
   ```bash
   julia --project -e "using Pkg; Pkg.instantiate()"
   ```

2. **Download coefficient files** to the `tmp/` directory:
   - EGM2008.gfc
   - EGM96.gfc
   - ggrx_1200a_sha.tab
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
├── binaries/           # Binary coefficient files
│   ├── EGM2008.bin
│   └── EGM2008_metadata.txt
└── tarballs/           # Compressed artifacts
    └── EGM2008.tar.gz
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
- (l_max+1)×(m_max+1)×8 bytes: C coefficients (Float64, column-major)
- (l_max+1)×(m_max+1)×8 bytes: S coefficients (Float64, column-major)

Indexing: `C[l+1, m+1]`, `S[l+1, m+1]` (1-based)

## Notes

- All artifacts contain **static fields only**
- Time-varying components (e.g., Mars seasonal variations) are not included
- Binary format is little-endian
- Tarballs include binary + metadata.txt
