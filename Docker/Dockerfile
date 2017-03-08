FROM jupyter/singleuser

MAINTAINER Alexander Barth <a.barth@ulg.ac.be>

EXPOSE 8888

USER root

ADD install_julia.sh .
RUN bash install_julia.sh

USER jovyan
RUN julia --eval 'Pkg.init()'
RUN julia --eval 'Pkg.add("IJulia"); using IJulia'


#USER=jovyan
#HOME=/home/$USER



# cat > mylist <<EOF
# EOF
# PkgDev
# PyPlot
# Gallium
# Interpolations
# Gadfly
# CatViews
# BlockArrays
# StatPlots
# ReverseDiffSource
# VideoIO
# Images
# ImageMagick
# Glob
# LightXML
# Requests
# LibGEOS
# BuildExecutable
# MAT
# GR
# WoodburyMatrices
# DataAssim
# NetCDF
# DistributedArrays
# Coverage
# NullableArrays
# ProfileView
# BenchmarkTools
# JSON
# JuMP
# Clp
# RDatasets
# SpecialFunctions
# EOF

# for i in $(cat mylist); do
#     julia --eval "Pkg.add(\"$i\")"
# done

# # precompilation
# for i in $(cat mylist); do
#     if [ "$i" != "PkgDev" ]; then
# 	julia --eval "using $i"
#     fi
# done


USER root
# jupyter kernelspec list
RUN mkdir /usr/local/share/jupyter/kernels/julia-0.5
RUN cp -Rp /home/jovyan/.julia/v0.5/IJulia/deps/julia-0.5/kernel.json /usr/local/share/jupyter/kernels/


USER jovyan

# smoke test that it's importable at least
RUN sh /srv/singleuser/singleuser.sh -h
CMD ["sh", "/srv/singleuser/singleuser.sh"]
