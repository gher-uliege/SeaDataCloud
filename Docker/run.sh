#!/bin/bash

if [ ! -d /home/jovyan/work/DIVAnd-Workshop-2018 ]; then
    cp -R /data/Diva-Workshops-master/notebooks /home/jovyan/work/DIVAnd-Workshop-2018
fi

exec /usr/local/bin/start-singleuser.sh --KernelSpecManager.ensure_native_kernel=False
