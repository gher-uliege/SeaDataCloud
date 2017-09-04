"""
Use the data file (provided in the data directory)
which contains only 2 profiles (temperature and salinity)
"""

datadir = "./data/";
ODVfile = joinpath(datadir, "BlackSea_2profiles.txt");
info("ODV file: " * ODVfile);

ODVdata = readODVspreadsheet(ODVfile);

@test length(ODVdata.profileList) == 2
@test length(ODVdata.profileList[1]) == 16
@test length(ODVdata.metadata) == 9
@test ODVdata.columnLabels[1] == "Cruise"
@test ODVdata.columnLabels[end] == "QV:ODV:SAMPLE"
@test ODVdata.metadata["Version"] == "ODV Spreadsheet V4.0"
@test ODVdata.metadata["DataType"] == "Profiles"
@test ODVdata.profileList[1][1][1] == "WOD05_BG000003"
