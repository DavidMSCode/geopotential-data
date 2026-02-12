#!/usr/bin/env julia

"""
Artifact generation script.

Usage:
    julia --project src/main.jl <model_id>
    julia --project src/main.jl all

Examples:
    julia --project src/main.jl EGM96
    julia --project src/main.jl all
"""

# Load the generation functions
using Downloads

include("gen artifacts.jl")

function ensure_coeff_file(model_id::String, coeff_file::String)
    if isfile(coeff_file)
        return true
    end

    meta = MODEL_METADATA[model_id]
    url = meta["source_url"]
    mkpath(dirname(coeff_file))

    println("Downloading $model_id coefficients from: $url")
    try
        Downloads.download(url, coeff_file)
        println("Downloaded to: $coeff_file")
        return true
    catch e
        println("Failed to download $model_id coefficients: $e")
        return false
    end
end

function generate_and_summarize(model_id::String, coeff_file::String, output_dir::String)
    """Generate artifact and print summary"""
    result = generate_model_artifact(model_id, coeff_file, output_dir)
    
    println("\n" * "="^70)
    println("GENERATION SUMMARY: $model_id")
    println("="^70)
    println("Model: $(result["model_id"])")
    println("Degree: l_max=$(result["l_max"]), m_max=$(result["m_max"])")
    println("Binary size: $(round(result["bin_size"]/1024^2, digits=2)) MB")
    println("Success!")
end

function main()
    if length(ARGS) < 1
        println("Usage: julia --project src/main.jl <model_id|all>")
        println("\nAvailable models:")
        for model_id in sort(collect(keys(MODEL_METADATA)))
            println("  $model_id: $(MODEL_METADATA[model_id]["full_name"])")
        end
        exit(1)
    end
    
    model_arg = ARGS[1]
    output_dir = dirname(@__DIR__)
    coeff_folder = "tmp"
    
    # Determine which models to generate
    models_to_generate = if model_arg == "all"
        collect(keys(MODEL_METADATA))
    else
        [model_arg]
    end
    
    # Generate each model
    successful = 0
    failed = 0
    
    for model_id in sort(models_to_generate)
        if !haskey(MODEL_METADATA, model_id)
            println("Unknown model: $model_id")
            failed += 1
            continue
        end
        
        coeff_filename = COEFF_FILENAMES[model_id]
        coeff_file = joinpath(coeff_folder, coeff_filename)
        
        if !ensure_coeff_file(model_id, coeff_file)
            println("Skipping $model_id - coefficient file unavailable: $coeff_file")
            failed += 1
            continue
        end
        
        try
            generate_and_summarize(model_id, coeff_file, output_dir)
            successful += 1
        catch e
            println("Error generating $model_id: $e")
            failed += 1
        end
    end
    
    # Create a single bundle artifact tarball
    if successful > 0
        bin_dir = joinpath(output_dir, "bin")
        tarball_dir = joinpath(output_dir, "tarballs")
        models_index = joinpath(bin_dir, "models.json")

        println("\n" * "="^70)
        println("Writing models index")
        println("="^70)
        write_models_index(models_index)
        println("Models index: $models_index")

        println("\n" * "="^70)
        println("Creating bundle artifact tarball")
        println("="^70)
        tarball = create_bundle_artifact(bin_dir, tarball_dir)
        tar_size = filesize(tarball)

        total_bin_size = sum(filesize(path) for path in readdir(bin_dir; join=true) if isfile(path))
        compression = total_bin_size > 0 ? (1 - tar_size / total_bin_size) * 100 : 0.0
        sha256_tar = bytes2hex(open(sha256, tarball))

        println("Bundle tarball: $tarball")
        println("Tarball size: $(round(tar_size/1024^2, digits=2)) MB")
        println("Compression: $(round(compression, digits=1))%")
        println("SHA256: $sha256_tar")
    end

    # Final summary
    if model_arg == "all"
        println("\n" * "="^70)
        println("BATCH GENERATION COMPLETE")
        println("="^70)
        println("Successful: $successful")
        println("Failed/Skipped: $failed")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
