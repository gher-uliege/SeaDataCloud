#!/bin/bash

JULIA_VERSION=0.6.2
# array with major, minor and revision number
JULIA_VERSION_PARTS=( ${JULIA_VERSION//./ } )
# just major and minor number
JULIA_VERSION_SHORT=${JULIA_VERSION_PARTS[0]}.${JULIA_VERSION_PARTS[1]}

mkdir /opt
cd /opt
#wget https://julialang.s3.amazonaws.com/bin/linux/x64/$JULIA_VERSION_SHORT/julia-$JULIA_VERSION-linux-x86_64.tar.gz
wget https://julialang-s3.julialang.org/bin/linux/x64/$JULIA_VERSION_SHORT/julia-$JULIA_VERSION-linux-x86_64.tar.gz

tar -xvf julia-$JULIA_VERSION-linux-x86_64.tar.gz
rm julia-$JULIA_VERSION-linux-x86_64.tar.gz
mv julia-* julia-$JULIA_VERSION

ln -s /opt/julia-$JULIA_VERSION/bin/julia /usr/local/bin





