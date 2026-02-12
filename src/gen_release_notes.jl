#!/usr/bin/env julia

"""
Generate release notes from model metadata.
"""

include("model_metadata.jl")

function generate_release_notes(output_file::String="")
    notes = """Initial release with geopotential coefficient artifacts for Earth (EGM96, EGM2008), Moon (GRGM1200A), and Mars (GMM3).

## Models & Citations

"""
    
    # Group models by body
    earth_models = ["EGM96", "EGM2008"]
    moon_models = ["GRGM1200A"]
    mars_models = ["GMM3"]
    
    # Earth models
    notes *= "**Earth Models:**\n\n"
    for model_id in earth_models
        meta = MODEL_METADATA[model_id]
        notes *= "- **$(meta["name"])** (degree/order $(meta["l_max"]))\n"
        notes *= "  $(meta["citation"])\n\n"
    end
    
    # Moon models
    notes *= "**Moon Model:**\n\n"
    for model_id in moon_models
        meta = MODEL_METADATA[model_id]
        notes *= "- **$(meta["name"])** (degree/order $(meta["l_max"]))\n"
        notes *= "  $(meta["citation"])\n\n"
    end
    
    # Mars models
    notes *= "**Mars Model:**\n\n"
    for model_id in mars_models
        meta = MODEL_METADATA[model_id]
        notes *= "- **$(meta["name"])** (degree/order $(meta["l_max"]))\n"
        notes *= "  $(meta["citation"])\n\n"
    end
    
    # Binary format section
    notes *= """## Binary Format

Each artifact includes:
- Int32: l_max (maximum degree)
- Int32: m_max (maximum order)
- Float64: Gravitational parameter (GM)
- Float64: Reference radius
- Float64[(l_max+1)*(m_max+1)]: C coefficients in column-major order
- Float64[(l_max+1)*(m_max+1)]: S coefficients in column-major order

All coefficients are normalized and stored in column-major order for efficient loading with mmap.
"""
    
    if !isempty(output_file)
        open(output_file, "w") do io
            write(io, notes)
        end
        println("Release notes written to: $output_file")
    end
    
    return notes
end

if abspath(PROGRAM_FILE) == @__FILE__
    output = isempty(ARGS) ? "/tmp/release_notes.txt" : ARGS[1]
    generate_release_notes(output)
else
    println("Usage: julia --project src/gen_release_notes.jl [output_file]")
    println("If no output_file is provided, notes will be written to /tmp/release_notes.txt")
end
