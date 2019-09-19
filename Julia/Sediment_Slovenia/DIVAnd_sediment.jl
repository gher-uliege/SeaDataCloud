using DIVAnd
using PyPlot
using NCDatasets
using Missings
using Interpolations
using Plots

if VERSION >= v"0.7"
    using Random
    using DelimitedFiles
    using Statistics
    using Printf
    using FileIO
else
    using Compat: @info, @warn, range, cat
end

"""

"""
function read_granulo(datafile::String)
    data, header = DelimitedFiles.readdlm(datafile, ';', header=true)
    header = header[:]
    obslon = Vector{Float64}(data[:,findfirst(header .== "Long")]);
    obslat = Vector{Float64}(data[:,findfirst(header .== "Lat")]);
    sand = Vector{Float64}(data[:,findfirst(header .== "sand (> 63 mm)")]);
    silt = Vector{Float64}(data[:,findfirst(header .== "silt")]);
    clay = Vector{Float64}(data[:,findfirst(header .== "clay (< 2 mm)")]);

    return obslon, obslat, sand, silt, clay;
end

"""

"""
function add_mask(bx, by, b)
    PyPlot.contourf(bx,by,permutedims(b,[2,1]), levels = [-1e5,0], colors = [[.5,.5,.5]])
end

"""

"""
function read_emodnet_bath(bathyfile::String)

    lonbathy = Vector{Float64};
    latbathy = Vector{Float64};
    local bathymetry
    open(bathyfile, "r") do f
        line = readline(f);
        ncols = parse(Int, match(r"\d+",line).match)
        line = readline(f);
        nrows = parse(Int, match(r"\d+",line).match)
        @info("Number of lines: $(nrows)")
        @info("Number of lines: $(ncols)")
        line = readline(f);
        XLLCORNER = parse(Float64, match(r"[-+]?[0-9]*\.?[0-9]+",line).match)
        line = readline(f);
        YLLCORNER = parse(Float64, match(r"[-+]?[0-9]*\.?[0-9]+",line).match)
        line = readline(f);
        CELLSIZE = parse(Float64, match(r"[-+]?[0-9]*\.?[0-9]+",line).match)
        line = readline(f);
        NODATA_VALUE = parse(Float64, match(r"[-+]?[0-9]*\.?[0-9]+",line).match)

        # Create lon and lat vectors
        lonbathy = collect(XLLCORNER:CELLSIZE:(XLLCORNER + (ncols-1) * CELLSIZE));
        latbathy = collect(YLLCORNER:CELLSIZE:(YLLCORNER + (nrows-1) * CELLSIZE));
        @info(length(lonbathy))
        @info(length(latbathy))

        bathymetry = Array{Float64, 2}(undef, (nrows, ncols))

        # Loop on the lines
        for ilines = 1:nrows
            dataline1 = readline(f);
            bathymetry[nrows - ilines + 1, :] = parse.(Float64, split(dataline1, " "));
        end
    end
    return lonbathy, latbathy, bathymetry
end

"""

"""
function bathy2nc(longrid::Array, latgrid::Array, bathy::Array, filename::String)

    Dataset(filename, "c") do ds

        nlon = length(longrid);
        nlat = length(latgrid);
        @info nlon

        # Define the dimensions "lon" and "lat"
        defDim(ds,"lon",nlon);
        defDim(ds,"lat",nlat);

        # Define a global attribute
        ds.attrib["title"] = "EMODnet Bathymetry"

        # Define the variables and coordinates
        lon = defVar(ds,"lon",Float64,("lon",))
        lat = defVar(ds,"lat",Float64,("lat",))

        # Attributes
        lat.attrib["long_name"] = "Latitude";
        lat.attrib["standard_name"] = "latitude";
        lat.attrib["units"] = "degrees_north";

        lon.attrib["long_name"] = "Longitude";
        lon.attrib["standard_name"] = "longitude";
        lon.attrib["units"] = "degrees_east";

        # Bathymetry
        bat = defVar(ds,"bat",Float64,("lon","lat"))
        bat.attrib["long_name"] = "elevation above sea level";
        bat.attrib["standard_name"] = "height";
        bat.attrib["units"] = "meters";

        # Fill the coord vectors and the fields
        lon[:] = longrid;
        lat[:] = latgrid;
        bat[:,:] = -permutedims(bathy, [2,1]);
    end
end

"""
"""
function emodnet2nc(asciifile::String, ncfile::String)
    lonb, latb, bat = read_emodnet_bath(asciifile);
    bathy2nc(lonb, latb, bat, ncfile);
end
