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
ENV JUPYTER /opt/conda/bin/jupyter

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

RUN i=OceanPlot;  julia --eval "Pkg.clone(\"https://github.com/gher-ulg/$i.jl\"); Pkg.build(\"$i\"); using $i"
RUN i=divand;     julia --eval "Pkg.clone(\"https://github.com/gher-ulg/$i.jl\"); Pkg.build(\"$i\"); using $i"

#RUN i=NCDatasets; julia --eval "Pkg.clone(\"https://github.com/Alexander-Barth/$i.jl\"); Pkg.build(\"$i\"); using $i"

RUN i=Requests; julia --eval "Pkg.add(\"$i\"); using $i"


#USER root
# install julia jupyter kernelspec list
#RUN mkdir /usr/local/share/jupyter/kernels/julia-0.6
#RUN cp -Rp /home/jovyan/.local/share/jupyter/kernels/julia-0.6 /usr/local/share/jupyter/kernels/

# no depreciation warnings
#RUN sed -i 's/"-i",/"-i", "--depwarn=no",/' /usr/local/share/jupyter/kernels/julia-0.6/kernel.json
RUN sed -i 's/"-i",/"-i", "--depwarn=no",/' /home/jovyan/.local/share/jupyter/kernels/julia-0.6/kernel.json

USER jovyan

# smoke test that it's importable at least
RUN sh /srv/singleuser/singleuser.sh -h
CMD ["sh", "/srv/singleuser/singleuser.sh"]
