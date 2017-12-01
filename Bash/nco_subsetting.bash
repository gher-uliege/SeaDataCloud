#!/bin/bash

datadir="/home/ctroupin/Data/EMODnet/"
outputdir=${datadir}'Adriatic/'

mkdir -pv ${outputdir}

declare -x lonmin=11.7
declare -x lonmax=20.
declare -x latmin=40.
declare -x latmax=46.

for datafiles in $(ls ${datadir}*nc); do
  outputfile=${outputdir}$(basename ${datafiles})
  echo ${datafiles} "-->" ${outputfile}
  ncea -d lat,${latmin},${latmax} -d lon,${lonmin},${lonmax} ${datafiles} ${outputfile}
done
