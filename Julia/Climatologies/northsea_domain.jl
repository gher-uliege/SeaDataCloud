dx, dy = 0.125, 0.125
lonr = -4.0:dx:10.
latr = 48.5:dy:62.
timerange = [Date(1900,1,1),Date(2017,12,31)]; # Used when extracting the obs

depthr = Float64.([0.,5., 10., 15., 20., 25., 30., 35, 40., 45, 50., 55, 60, 65., 70,
    75, 80, 85, 90, 95, 100, 125, 150, 175, 200, 225, 250,
    275, 300, 325, 350, 375, 400, 425, 450, 475, 500, 550, 600, 650, 700]);