"""
Model metadata for geopotential coefficient artifacts.

Each model entry contains:
- name: Short identifier used by the package
- full_name: Full descriptive name
- source_url: URL where coefficients can be downloaded
- distributor: Organization providing the data
- gravitational_parameter: GM value in specified units
- parameter_error: Uncertainty in GM (if available)
- reference_radius: Reference radius for the model
- units: Unit system (e.g., "m s" for meters/seconds, "km s" for kilometers/seconds)
- l_max: Maximum degree
- m_max: Maximum order
- normalized: Whether coefficients are normalized
- altimetry_data: Whether model includes altimetry data
- ground_data: Whether model includes ground-based measurements
- satellite_data: Whether model includes satellite tracking data
- description: Detailed description of the model
- provider: Original data provider
- license: License/usage terms
- note: Additional notes or caveats
"""

const MODEL_METADATA = Dict(
    "EGM2008" => Dict(
        "name" => "EGM2008",
        "full_name" => "Earth Gravitational Model 2008 (EGM2008) Tide Free",
        "source_url" => "https://icgem.gfz.de/getmodel/gfc/c50128797a9cb62e936337c890e4425f03f0461d7329b09a8cc8561504465340/EGM2008.gfc",
        "distributor" => "International Centre for Global Earth Models (ICGEM)",
        "type" => "Static",
        "gravitational_parameter" => 0.3986004415E+15,
        "parameter_error" => 0.0000000000E+00,
        "reference_radius" => 0.63781363E+07,
        "units" => "m s",
        "l_max" => 2190,
        "m_max" => 2190,
        "normalized" => true,
        "altimetry_data" => true,
        "ground_data" => true,
        "satellite_data" => true,
        "description" => "The Earth Gravitational Model 2008 (EGM2008) is a high-resolution model of Earth's gravitational field, providing coefficients up to degree and order 2190. It is based on satellite data, terrestrial measurements, and altimetry, and is widely used for geodetic and geophysical applications.",
        "provider" => "National Geo-Spatial Intelligence Agency (NGA) and the National Aeronautics and Space Administration (NASA)",
        "license" => "Public Domain",
        "citation" => "Pavlis, N. K., Holmes, S. A., Kenyon, S. C., & Factor, J. K. (2012). The development and evaluation of the Earth Gravitational Model 2008 (EGM2008). Journal of Geophysical Research: Solid Earth, 117(B4). https://doi.org/10.1029/2011jb008916
",
        "note" => "",
    ),
    "EGM96" => Dict(
        "name" => "EGM96",
        "full_name" => "Earth Gravitational Model 1996 (EGM96) Tide Free",
        "source_url" => "https://icgem.gfz.de/getmodel/gfc/971b0a3b49a497910aad23cd85e066d4cd9af0aeafe7ce6301a696bed8570be3/EGM96.gfc",
        "distributor" => "International Centre for Global Earth Models (ICGEM)",
        "gravitational_parameter" => 0.3986004415E+15,
        "parameter_error" => 0.0000000000E+00,
        "reference_radius" => 0.6378136300E+07,
        "units" => "m s",
        "l_max" => 360,
        "m_max" => 360,
        "normalized" => true,
        "altimetry_data" => true,
        "ground_data" => true,
        "satellite_data" => true,
        "description" => "The Earth Gravitational Model 1996 (EGM96) is a widely used model of Earth's gravitational field, providing coefficients up to degree and order 360. It is based on satellite data, terrestrial measurements, and altimetry, and has been used for various geodetic and geophysical applications.",
        "provider" => "National Geo-Spatial Intelligence Agency (NGA) and the National Aeronautics and Space Administration (NASA)",
        "license" => "Public Domain",
        "citation" => "Lemoine, F. G., et al. (1998), The development of the joint NASA GSFC and NIMA geopotential model EGM96 https://ntrs.nasa.gov/citations/19980218814",
        "note" => "EGM96 is an older model and has been superseded by EGM2008, which provides higher resolution and improved accuracy. However, EGM96 is still used in some applications and serves as a reference for comparing newer models.",
    ),
    "GRGM1200A" => Dict(
        "name" => "GRGM1200A",
        "full_name" => "Grail Gravitational Model 1200A (GRGM1200A) Tide Free",
        "source_url" => "http://pds-geosciences.wustl.edu/grail/grail-l-lgrs-5-rdr-v1/grail_1001/shadr/gggrx_1200a_sha.tab",
        "distributor" => "Planetary Geodesy Data Archive (PGDA)",
        "gravitational_parameter" => 4.9028001224453001e+12,
        "reference_radius" => 1.7380000000000000e+06,
        "units" => "m s",
        "l_max" => 1200,
        "m_max" => 1200,
        "normalized" => true,
        "altimetry_data" => false,
        "ground_data" => false,
        "satellite_data" => true,
        "description" => "The Grail Gravitational Model 1200A (GRGM1200A) is a high-resolution model of the Moon's gravitational field, providing coefficients up to degree and order 1200. It is based on data from the Gravity Recovery and Interior Laboratory (GRAIL) mission, which mapped the lunar gravity field with unprecedented precision.",
        "provider" => "NASA Jet Propulsion Laboratory (JPL)",
        "license" => "Public Domain",
        "citation" => "Goossens, S., Sabaka, T. J., Wieczorek, M. A., Neumann, G. A., Mazarico, E., Lemoine, F. G., Nicholas, J. B., Smith, D. E., & Zuber, M. T. (2020). High‐Resolution Gravity Field Models from GRAIL Data and Implications for Models of the Density Structure of the Moon’s Crust. Journal of Geophysical Research: Planets, 125(2). https://doi.org/10.1029/2019je006086",
        "note" => "",
    ),
    "GMM3" => Dict(
        "name" => "GMM3",
        "full_name" => "Mars Global Gravitational Model 3 (GMM-3) Tide Free - Static Field Only",
        "source_url" => "https://pds-geosciences.wustl.edu/mro/mro-m-rss-5-sdp-v1/mrors_1xxx/data/shadr/gmm3_120_sha.tab",
        "distributor" => "Planetary Geodesy Data Archive (PGDA)",
        "gravitational_parameter" => 4.282837362e+13,
        "reference_radius" => 3.3960000000000000e+06,
        "units" => "m s",
        "l_max" => 120,
        "m_max" => 120,
        "normalized" => true,
        "altimetry_data" => false,
        "ground_data" => false,
        "satellite_data" => true,
        "description" => "The Mars Global Gravitational Model 3 (GMM-3) is a model of Mars' gravitational field, providing coefficients up to degree and order 120. It is based on data from the Mars Global Surveyor (MGS) mission, which mapped the Martian gravity field and provided insights into the planet's interior structure.",
        "provider" => "NASA Jet Propulsion Laboratory (JPL)",
        "license" => "Public Domain",
        "citation" => "Genova, A., Goossens, S., Lemoine, F. G., Mazarico, E., Neumann, G. A., Smith, D. E., & Zuber, M. T. (2016). Seasonal and static gravity field of Mars from MGS, Mars Odyssey and MRO radio science. Icarus, 272, 228–245. https://doi.org/10.1016/j.icarus.2016.02.050",
        "note" => "Time-varying zonal coefficients (C₂₀, C₃₀) due to seasonal CO₂ ice cap variations are NOT included in this static field artifact.",
    ),
)

const MODEL_COEFF_START_LINE = Dict(
    "EGM2008" => 22,
    "EGM96" => 22,
    "GRGM1200A" => 2,
    "GMM3" => 2,
)

const COEFF_FILENAMES = Dict(
    "EGM2008" => "EGM2008.gfc",
    "EGM96" => "EGM96.gfc",
    "GRGM1200A" => "gggrx_1200a_sha.tab",
    "GMM3" => "gmm3_120_sha.tab",
)
