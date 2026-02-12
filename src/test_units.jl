#!/usr/bin/env julia

"""
Unit tests for coefficient parsing and conversion functions.
"""

include("gen artifacts.jl")

function test_coeffs_to_matrices()
    println("Testing coeffs_to_matrices...")
    
    # Sample coefficient data
    coeffs = Dict(
        (2, 0) => (-4.84165e-04, 0.0),
        (2, 1) => (-2.06616e-10, 1.38441e-09),
        (2, 2) => (2.43938e-06, -1.40027e-06),
        (3, 0) => (9.57161e-07, 0.0),
        (3, 1) => (2.03046e-06, 2.48200e-07)
    )
    
    l_max, m_max, C, S = coeffs_to_matrices(coeffs)
    
    # Verify dimensions
    @assert l_max == 3 "Expected l_max=3, got $l_max"
    @assert m_max == 2 "Expected m_max=2, got $m_max"
    @assert size(C) == (4, 3) "Expected C size (4,3), got $(size(C))"
    @assert size(S) == (4, 3) "Expected S size (4,3), got $(size(S))"
    
    # Verify values
    @assert C[3, 1] ≈ -4.84165e-04 "C[2,0] mismatch"
    @assert S[3, 2] ≈ 1.38441e-09 "S[2,1] mismatch"
    
    # Verify zeros
    @assert C[1, 1] == 0.0 "C[0,0] should be zero"
    @assert S[3, 1] == 0.0 "S[2,0] should be zero"
    
    println("  ✓ Matrix conversion passed")
end

function test_binary_write_read()
    println("Testing binary write/read...")
    
    # Create test matrices
    l_max, m_max = 3, 2
    gm = 3.986004415e14
    ref_rad = 6.378137e6
    C = rand(Float64, l_max + 1, m_max + 1)
    S = rand(Float64, l_max + 1, m_max + 1)
    
    # Write to temp file
    tmpfile = tempname() * ".bin"
    try
        write_binary_coefficients(tmpfile, l_max, m_max, C, S, gm, ref_rad)
        
        # Read back
        open(tmpfile, "r") do io
            l_read = read(io, Int32)
            m_read = read(io, Int32)
            gm_read = read(io, Float64)
            ref_read = read(io, Float64)
            
            @assert l_read == l_max "l_max mismatch"
            @assert m_read == m_max "m_max mismatch"
            @assert gm_read ≈ gm "GM mismatch"
            @assert ref_read ≈ ref_rad "reference radius mismatch"
            
            n = (l_max + 1) * (m_max + 1)
            
            # Read binary data
            data = Vector{Float64}(undef, 2 * n)
            read!(io, data)
            
            C_read = reshape(data[1:n], l_max + 1, m_max + 1)
            S_read = reshape(data[n+1:2n], l_max + 1, m_max + 1)
            
            @assert C_read ≈ C "C matrix mismatch"
            @assert S_read ≈ S "S matrix mismatch"
        end
        
        println("  ✓ Binary I/O passed")
    finally
        isfile(tmpfile) && rm(tmpfile)
    end
end

function test_metadata_write()
    println("Testing metadata write...")
    
    tmpfile = tempname() * ".txt"
    try
        write_metadata_file(tmpfile, "EGM2008")
        
        @assert isfile(tmpfile) "Metadata file not created"
        
        content = read(tmpfile, String)
        @assert occursin("EGM2008", content) "Missing model name"
        @assert occursin("l_max", content) "Missing l_max"
        @assert occursin("Binary Format", content) "Missing format description"
        
        println("  ✓ Metadata write passed")
    finally
        isfile(tmpfile) && rm(tmpfile)
    end
end

function run_tests()
    println("="^70)
    println("Running Unit Tests")
    println("="^70)
    
    try
        test_coeffs_to_matrices()
        test_binary_write_read()
        test_metadata_write()
        
        println("\n" * "="^70)
        println("✅ All tests passed!")
        println("="^70)
    catch e
        println("\n❌ Test failed: $e")
        rethrow(e)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
end
