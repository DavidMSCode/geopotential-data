#= 
To generate artifact tarballs from SHG coefficient files a few steps are required.

1. Procure the SHG coefficient files.
    - EGM2008
    - EGM96
    - GRGM1200A
    - GMM3

NOTE: This script generates STATIC field artifacts only. Some models (e.g., GMM-3 for Mars)
include time-varying zonal coefficients (C₂₀, C₃₀) due to seasonal CO₂ ice cap variations.
These time-varying components are NOT included in the generated binaries and must be
handled separately if needed.
    
2 Read the text files to get coefficients as well as data such as gravitational parameter, reference radius, and maximum degree and order, whether the coefficients are normalized, and the type of tide system.
    - Manually writeout a file with this metadata for each model.
        Include:
        - name (used by the package to identify the model, e.g. "EGM2008")
        - full name (e.g. "Earth Gravitational Model 2008")
        - source URL
        - gravitational parameter (GM)
        - reference radius (R)
        - maximum degree and order (l_max, m_max)
        - whether coefficients are normalized (normalized)
        - description
        - provider
        - license

3. Write the data to a binary file in a format that can be read efficiently by the package. The current format is:
  - 4 bytes: Int32 l_max
  - 4 bytes: Int32 m_max
  - (l_max + 1) * (m_max + 1) * 8 bytes: C coefficients as Float64, in C++ order (l outer, m inner)
  - (l_max + 1) * (m_max + 1) * 8 bytes: S coefficients as Float64, in C++ order (l outer, m inner)

4. Create a tarball containing the binary file and a manifest with metadata.
 =#

# Load model metadata from separate file
include("model_metadata.jl")

# Load required packages
using Mmap
using Tar, CodecZlib
using SHA
using Dates

# Files downloaded to a temporary folder
const foldername = "tmp"

"""
    read_ICGEM_coeff_file(filename, start_line)

Parse ICGEM format coefficient file (.gfc) used by Earth models (EGM2008, EGM96).

ICGEM format has lines like:
    gfc    2    0  -4.84165143790815e-04  0.00000000000000e+00  7.48e-12  0.00e+00

Returns a Dict with keys (l, m) => (C, S)
"""
function read_ICGEM_coeff_file(filename::AbstractString, start_line::Int)
    coeffs = Dict{Tuple{Int,Int}, Tuple{Float64,Float64}}()
    
    open(filename, "r") do io
        for (line_num, line) in enumerate(eachline(io))
            line_num < start_line && continue
            
            # Skip empty lines and comments
            stripped = strip(line)
            isempty(stripped) && continue
            startswith(stripped, '#') && continue
            
            # Parse coefficient lines starting with "gfc" or "gfct"
            if startswith(stripped, "gfc")
                parts = split(stripped)
                if length(parts) >= 5
                    l = parse(Int, parts[2])
                    m = parse(Int, parts[3])
                    # Handle Fortran D-notation (e.g., "1.0d0") by replacing d/D with e
                    C = parse(Float64, replace(parts[4], r"[dD]" => "e"))
                    S = parse(Float64, replace(parts[5], r"[dD]" => "e"))
                    coeffs[(l, m)] = (C, S)
                end
            end
        end
    end
    
    return coeffs
end

"""
    read_PGDA_coeff_file(filename, start_line)

Parse NASA PGDA format coefficient file (.tab) used by Moon/Mars models (GRGM1200A, GMM3).

PGDA format is column delimited with commas and has lines like:
    2,    1, 5.9031495993080755e-10,-4.9433617424482412e-11, 5.2065234840578776e-12, 5.2324542200737978e-12  

Returns a Dict with keys (l, m) => (C, S)
"""
function read_PGDA_coeff_file(filename::AbstractString, start_line::Int)
    coeffs = Dict{Tuple{Int,Int}, Tuple{Float64,Float64}}()
    
    open(filename, "r") do io
        for (line_num, line) in enumerate(eachline(io))
            line_num < start_line && continue
            
            # Skip empty lines and comments
            stripped = strip(line)
            isempty(stripped) && continue
            startswith(stripped, '#') && continue
            
            # Split on commas for PGDA format
            parts = split(stripped, ',')
            if length(parts) >= 4
                try
                    l = parse(Int, strip(parts[1]))
                    m = parse(Int, strip(parts[2]))
                    C = parse(Float64, strip(parts[3]))
                    S = parse(Float64, strip(parts[4]))
                    coeffs[(l, m)] = (C, S)
                catch
                    # Skip lines that can't be parsed
                    continue
                end
            end
        end
    end
    
    return coeffs
end

"""
    read_coeff_file(model_id, filename)

Read coefficients for a specific model using the appropriate parser.
Automatically selects ICGEM or PGDA format based on model ID.
"""
function read_coeff_file(model_id::AbstractString, filename::AbstractString)
    start_line = MODEL_COEFF_START_LINE[model_id]
    
    if model_id in ["EGM2008", "EGM96"]
        return read_ICGEM_coeff_file(filename, start_line)
    elseif model_id in ["GRGM1200A", "GMM3"]
        return read_PGDA_coeff_file(filename, start_line)
    else
        error("Unknown model ID: $model_id")
    end
end

"""
    coeffs_to_matrices(coeffs_dict)

Convert coefficient dictionary to C and S matrices.
Returns (l_max, m_max, C, S) where C and S are indexed as C[l+1, m+1].
"""
function coeffs_to_matrices(coeffs_dict::Dict{Tuple{Int,Int}, Tuple{Float64,Float64}})
    # Find max degree and order
    l_max = maximum(k[1] for k in keys(coeffs_dict))
    m_max = maximum(k[2] for k in keys(coeffs_dict))
    
    # Allocate matrices
    C = zeros(Float64, l_max + 1, m_max + 1)
    S = zeros(Float64, l_max + 1, m_max + 1)
    
    # Fill matrices
    for ((l, m), (c, s)) in coeffs_dict
        C[l + 1, m + 1] = c
        S[l + 1, m + 1] = s
    end
    
    return l_max, m_max, C, S
end

"""  
    write_binary_coefficients(binfile, l_max, m_max, C, S, gm, ref_rad)

Write coefficient matrices to binary file using mmap for efficiency.

Binary format:
  - Int32: l_max
  - Int32: m_max
  - Float64: gravitational_parameter (GM)
  - Float64: reference_radius
  - Float64 array (n elements): C coefficients in Julia column-major order, where n = (l_max+1) * (m_max+1)
  - Float64 array (n elements): S coefficients in Julia column-major order, where n = (l_max+1) * (m_max+1)
"""
function write_binary_coefficients(binfile::AbstractString, l_max::Int, m_max::Int, 
                                   C::Matrix{Float64}, S::Matrix{Float64},
                                   gm::Float64, ref_rad::Float64)
    n = (l_max + 1) * (m_max + 1)
    header_bytes = 2 * sizeof(Int32) + 2 * sizeof(Float64)
    total_floats = 2 * n
    data_bytes = total_floats * sizeof(Float64)
    
    mkpath(dirname(binfile))
    
    open(binfile, "w+") do io
        # Write header
        write(io, Int32(l_max))
        write(io, Int32(m_max))
        write(io, Float64(gm))
        write(io, Float64(ref_rad))
        
        # Pre-allocate file
        seek(io, header_bytes + data_bytes - 1)
        write(io, UInt8(0))
        
        # Memory map and write data
        data = Mmap.mmap(io, Vector{Float64}, total_floats, header_bytes)
        
        # Copy C coefficients (flatten column-major)
        copyto!(view(data, 1:n), vec(C))
        
        # Copy S coefficients
        copyto!(view(data, n+1:2n), vec(S))
        
        # Ensure data is written to disk
        Mmap.sync!(data)
    end
    
    return binfile
end

"""
    write_metadata_file(metafile, model_id)

Write metadata text file for the model artifact.
"""
function write_metadata_file(metafile::AbstractString, model_id::AbstractString, bin_sha256::AbstractString="")
    meta = MODEL_METADATA[model_id]
    
    open(metafile, "w") do io
        println(io, "Model: $(meta["full_name"])")
        println(io, "ID: $(meta["name"])")
        println(io, "Provider: $(meta["provider"])")
        println(io, "Distributor: $(meta["distributor"])")
        println(io, "License: $(meta["license"])")
        println(io, "")
        println(io, "Gravitational Parameter (GM): $(meta["gravitational_parameter"]) $(meta["units"])²")
        println(io, "Reference Radius: $(meta["reference_radius"]) $(split(meta["units"])[1])")
        println(io, "Max Degree (l_max): $(meta["l_max"])")
        println(io, "Max Order (m_max): $(meta["m_max"])")
        println(io, "Normalized: $(meta["normalized"])")
        println(io, "")
        println(io, "Data Sources:")
        println(io, "  Altimetry: $(meta["altimetry_data"])")
        println(io, "  Ground measurements: $(meta["ground_data"])")
        println(io, "  Satellite tracking: $(meta["satellite_data"])")
        println(io, "")
        println(io, "Description:")
        println(io, "  $(meta["description"])")
        println(io, "")
        println(io, "Citation:")
        println(io, "  $(meta["citation"])")
        println(io, "")
        println(io, "Source URL: $(meta["source_url"])")
        if !isempty(bin_sha256)
            println(io, "")
            println(io, "Binary SHA256: $bin_sha256")
        end
        println(io, "")
        println(io, "Binary Format:")
        println(io, "  - 4 bytes: Int32 l_max")
        println(io, "  - 4 bytes: Int32 m_max")
        println(io, "  - 8 bytes: Float64 Gravitational Parameter (GM)")
        println(io, "  - 8 bytes: Float64 Reference Radius")
        println(io, "  - (l_max+1)*(m_max+1)*8 bytes: C coefficients (Float64, column-major)")
        println(io, "  - (l_max+1)*(m_max+1)*8 bytes: S coefficients (Float64, column-major)")
        println(io, "  Endianness: Little-endian")
        println(io, "  Index Convention: C[l+1, m+1], S[l+1, m+1] (1-based, Julia)")
        println(io, "")
        if !isempty(meta["note"])
            println(io, "Note: $(meta["note"])")
            println(io, "")
        end
        println(io, "Generated: $(Dates.now())")
    end
    
    return metafile
end

"""
    create_artifact_tarball(model_id, binfile, metafile, output_dir)

Create compressed tarball containing binary coefficient file and metadata.
Returns path to the tarball.
"""
function create_artifact_tarball(model_id::AbstractString, binfile::AbstractString, 
                                 metafile::AbstractString, output_dir::AbstractString)
    mkpath(output_dir)
    
    # Create temporary directory with artifact contents
    temp_artifact = mktempdir()
    cp(binfile, joinpath(temp_artifact, "$(model_id).bin"))
    cp(metafile, joinpath(temp_artifact, "metadata.txt"))
    
    # Create compressed tarball
    tarball = joinpath(output_dir, "$(model_id).tar.gz")
    open(tarball, "w") do io
        stream = GzipCompressorStream(io)
        Tar.create(temp_artifact, stream)
        close(stream)
    end
    
    return tarball
end

"""
    generate_model_artifact(model_id, coeff_file, output_dir)

Complete pipeline to generate binary artifact from text coefficient file.

Steps:
1. Parse coefficient file
2. Convert to matrices
3. Write binary file
4. Create metadata file
5. Package into tarball

Returns Dict with file paths and checksums.
"""
function generate_model_artifact(model_id::AbstractString, coeff_file::AbstractString, 
                                 output_dir::AbstractString)
    println("\n" * "="^70)
    println("Generating artifact for: $model_id")
    println("="^70)
    
    # Parse coefficients
    print("Reading coefficient file... ")
    flush(stdout)
    coeffs = read_coeff_file(model_id, coeff_file)
    println("✓ ($(length(coeffs)) coefficients)")
    
    # Convert to matrices
    print("Converting to matrices... ")
    flush(stdout)
    l_max, m_max, C, S = coeffs_to_matrices(coeffs)
    println("✓ (l_max=$l_max, m_max=$m_max)")
    
    # Get gravitational parameter and reference radius from metadata
    meta = MODEL_METADATA[model_id]
    gm = meta["gravitational_parameter"]
    ref_rad = meta["reference_radius"]
    
    # Write binary file
    binary_dir = joinpath(output_dir, "binaries")
    binfile = joinpath(binary_dir, "$(model_id).bin")
    print("Writing binary file... ")
    flush(stdout)
    write_binary_coefficients(binfile, l_max, m_max, C, S, gm, ref_rad)
    bin_size = filesize(binfile)
    println("✓ ($(round(bin_size/1024^2, digits=2)) MB)")
    
    # Compute binary checksum (for metadata)
    sha256_bin = bytes2hex(open(sha256, binfile))

    # Write metadata
    metafile = joinpath(binary_dir, "$(model_id)_metadata.txt")
    print("Writing metadata... ")
    flush(stdout)
    write_metadata_file(metafile, model_id, sha256_bin)
    println("✓")
    
    # Create tarball
    tarball_dir = joinpath(output_dir, "tarballs")
    print("Creating tarball... ")
    flush(stdout)
    tarball = create_artifact_tarball(model_id, binfile, metafile, tarball_dir)
    tar_size = filesize(tarball)
    println("✓ ($(round(tar_size/1024^2, digits=2)) MB, $(round((1-tar_size/bin_size)*100, digits=1))% compression)")
    
    # Compute checksums
    print("🔐 Computing checksums... ")
    flush(stdout)
    sha256_bin = bytes2hex(open(sha256, binfile))
    sha256_tar = bytes2hex(open(sha256, tarball))
    println("✓")
    
    println("\nArtifact generation complete")
    println("   Binary:  $binfile")
    println("   Tarball: $tarball")
    println("\nSHA256 checksums:")
    println("   Binary:  $sha256_bin")
    println("   Tarball: $sha256_tar")
    
    return Dict(
        "model_id" => model_id,
        "l_max" => l_max,
        "m_max" => m_max,
        "binfile" => binfile,
        "tarball" => tarball,
        "bin_size" => bin_size,
        "tar_size" => tar_size,
        "sha256_bin" => sha256_bin,
        "sha256_tar" => sha256_tar
    )
end
