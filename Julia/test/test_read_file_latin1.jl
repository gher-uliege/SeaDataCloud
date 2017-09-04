"""
Use the data file with 10 profiles
and some non UFC-8 characters
"""

datadir = "./data/";
ODVfile = joinpath(datadir, "BlackSea_10profiles_Latin1.txt");
info("ODV file: " * ODVfile);

ODVdata = readODVspreadsheet(ODVfile);

@test length(ODVdata.profileList) == 10
@test length(ODVdata.profileList[1]) == 16
@test length(ODVdata.metadata) == 10
@test ODVdata.columnLabels[1] == "Cruise"
@test ODVdata.columnLabels[end] == "QV:ODV:SAMPLE"
@test ODVdata.metadata["Version"] == "ODV Spreadsheet V4.0"
@test ODVdata.metadata["DataType"] == "Profiles"
@test ODVdata.metadata["TestString"] == "Ça peut être @ ñù²?"
@test ODVdata.profileList[3][4][1] == "1991-09-04T02:12"
