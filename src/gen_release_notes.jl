#!/usr/bin/env julia

"""
Generate release notes from model metadata.
"""

using TOML

const METADATA_FILE = joinpath(@__DIR__, "model_metadata.toml")
const MODELS_TOML = TOML.parsefile(METADATA_FILE)

# Convert TOML to metadata dicts
const MODEL_METADATA = Dict(
    model_id => Dict(String(k) => v for (k, v) in pairs(section))
    for (model_id, section) in MODELS_TOML
)

function generate_release_notes(output_file::String="")
    notes = """Initial release with geopotential coefficient artifacts for Earth (EGM96, EGM2008), Moon (GRGM1200A), and Mars (GMM3).

## Models & Citations
The following models are included as binary files in this release:

"""
    
    # Group models by body
    models_by_body = Dict{String, Vector{String}}()
    for model_id in sort(collect(keys(MODEL_METADATA)))
        meta = MODEL_METADATA[model_id]
        body = meta["body"]
        if !haskey(models_by_body, body)
            models_by_body[body] = []
        end
        push!(models_by_body[body], model_id)
    end
    
    # Generate sections for each body (sorted by body name)
    for body in sort(collect(keys(models_by_body)))
        model_ids = models_by_body[body]
        
        # Format heading
        if length(model_ids) == 1
            notes *= "**$body Model:**\n\n"
        else
            notes *= "**$body Models:**\n\n"
        end
        
        # List models for this body
        for model_id in sort(model_ids)
            meta = MODEL_METADATA[model_id]
            notes *= "- **$(meta["name"])** (degree/order $(meta["l_max"]))\n"
            notes *= "  $(meta["citation"])\n\n"
        end
    end
    
    # Binary format section
    notes *= """## Binary Format

Each bin includes:
- Int32: l_max (maximum degree)
- Int32: m_max (maximum order)
- Float64: Gravitational parameter (GM)
- Float64: Reference radius
- Float64[(l_max+1)*(m_max+1)]: C coefficients in column-major order
- Float64[(l_max+1)*(m_max+1)]: S coefficients in column-major order

All coefficients are normalized and stored in column-major order for efficient loading with mmap.

In addition an index file (models.json) and a metadata file (\\<model\\>_metadata.json) are included with detailed information about each model.
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
