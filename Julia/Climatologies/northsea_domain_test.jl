dx, dy = 0.25, 0.25
lonr = -4.0:dx:10.
latr = 48.5:dy:62.
timerange = [Date(1900,1,1),Date(2017,12,31)]; # Used when extracting the obs

depthr = Float64.([0.,5., 10., 15., 20., 25., 30., 35, 40.]);
