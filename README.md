# SeaDataCloud
Tools and interfaces to work with DIVA interpolation software tool. 

## Re-gridding

Re-gridding is the action of interpolation a field from a grid to another grid, usually with a higher resolution.     
[nco](http://nco.sourceforge.net) provides a tool [`ncremap`](http://nco.sourceforge.net/nco.html#ncremap) for this purpose. 

### Installation

1. Download and compile [ESMF](https://www.earthsystemcog.org/projects/esmf/download/)
2. Download a recent version of nco.

### Usage

```bash
ncremap -i data.nc -d grid.nc -o data_regridded.nc
```
where:
- *data.nc* is the original file containing the fields,
- *grid.nc* is another file containing the new grid
- *data_regridded.nc* is the final output file with the fields interpolated onto the new grid.

Note that the input file needs to have lon and lat as coordinates. If that's not te case, one can always use [`ncrename`](https://linux.die.net/man/1/ncrename), for instance:
```bash
ncrename -d x,lon -v x,lon in.nc
```
* the dimension *x* is renamed *lon*
* the variable *x* is renamed *lon*

### Troubleshooting

#### NetCDF 

If you get errors related to netCDF, define the environment variables as in:
http://www.earthsystemmodeling.org/esmf_releases/last_built/ESMF_usrdoc/node9.html#SECTION00093200000000000000
