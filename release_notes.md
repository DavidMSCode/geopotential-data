Initial release with geopotential coefficient artifacts for Earth (EGM96, EGM2008), Moon (GRGM1200A), and Mars (GMM3).

## Models & Citations
The following models are included as binary files in this release:

**Earth Models:**

- **EGM2008** (degree/order 2190)
  Pavlis, N. K., Holmes, S. A., Kenyon, S. C., & Factor, J. K. (2012). The development and evaluation of the Earth Gravitational Model 2008 (EGM2008). Journal of Geophysical Research: Solid Earth, 117(B4). https://doi.org/10.1029/2011jb008916

- **EGM96** (degree/order 360)
  Lemoine, F. G., et al. (1998), The development of the joint NASA GSFC and NIMA geopotential model EGM96 https://ntrs.nasa.gov/citations/19980218814

**Mars Model:**

- **GMM3** (degree/order 120)
  Genova, A., Goossens, S., Lemoine, F. G., Mazarico, E., Neumann, G. A., Smith, D. E., & Zuber, M. T. (2016). Seasonal and static gravity field of Mars from MGS, Mars Odyssey and MRO radio science. Icarus, 272, 228–245. https://doi.org/10.1016/j.icarus.2016.02.050

**Moon Model:**

- **GRGM1200A** (degree/order 1200)
  Goossens, S., Sabaka, T. J., Wieczorek, M. A., Neumann, G. A., Mazarico, E., Lemoine, F. G., Nicholas, J. B., Smith, D. E., & Zuber, M. T. (2020). High‐Resolution Gravity Field Models from GRAIL Data and Implications for Models of the Density Structure of the Moon's Crust. Journal of Geophysical Research: Planets, 125(2). https://doi.org/10.1029/2019je006086

## Binary Format

Each bin includes:
- Int32: l_max (maximum degree)
- Int32: m_max (maximum order)
- Float64: Gravitational parameter (GM)
- Float64: Reference radius
- Float64[(l_max+1)*(m_max+1)]: C coefficients in column-major order
- Float64[(l_max+1)*(m_max+1)]: S coefficients in column-major order

All coefficients are normalized and stored in column-major order for efficient loading with mmap.

In addition an index file (models.json) and a metadata file (\<model\>_metadata.json) are included with detailed information about each model.
