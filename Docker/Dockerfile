# build as:
# sudo docker build -t jupyterhub/singleuser .

FROM jupyter/singleuser

MAINTAINER Alexander Barth <a.barth@ulg.ac.be>

EXPOSE 8888

USER root

RUN apt-get update
RUN apt-get install -y libnetcdf-dev
#RUN apt-get install -y ca-certificates
#RUN echo "davfs2 davfs2/suid_file boolean true" | debconf-set-selections --
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y davfs2
RUN apt-get install -y libzmq3-dev

RUN conda install ipywidgets

# Install julia

ADD install_julia.sh .
RUN bash install_julia.sh
RUN rm install_julia.sh

# install packages as user (to that the user can temporarily update them if necessary)
# and precompilation

USER jovyan

RUN julia --eval 'Pkg.init()'

RUN i=ZMQ; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=IJulia; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=NetCDF; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=PyPlot; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=Interpolations; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=MAT; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=JSON; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=NullableArrays; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=SpecialFunctions; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=Interact; julia --eval "Pkg.add(\"$i\"); using $i"
RUN i=Roots; julia --eval "Pkg.add(\"$i\"); using $i"

RUN i=OceanPlot; julia --eval "Pkg.clone(\"https://github.com/gher-ulg/$i.jl\"); using $i"
RUN i=divand; julia   --eval "Pkg.clone(\"https://github.com/gher-ulg/$i.jl\"); using $i"


USER root
# install julia jupyter kernelspec list
RUN mkdir /usr/local/share/jupyter/kernels/julia-0.5
RUN cp -Rp /home/jovyan/.julia/v0.5/IJulia/deps/julia-0.5/kernel.json /usr/local/share/jupyter/kernels/

USER jovyan

# smoke test that it's importable at least
RUN sh /srv/singleuser/singleuser.sh -h
CMD ["sh", "/srv/singleuser/singleuser.sh"]
