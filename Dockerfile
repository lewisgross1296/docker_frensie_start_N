# this docker file is used to build FRENSIE and it's dependencies for use on 
# the CHTC HPC cluster
FROM ubuntu:18.04

RUN useradd -u 8877 simulator

RUN apt-get update &&  \
    apt-get install -y \
        git \
        wget \
        doxygen \
        libpcre3 libpcre3-dev \
        gfortran \
        gcc \
        libssl-dev \
        libblas-dev \
        liblapack-dev \
        python-pip \
        python-dev \
        libeigen3-dev \
        autogen \
        autoconf \
        libtool &&  \
    pip install numpy

RUN mkdir /home/simulator &&  \
    mkdir /home/simulator/dependencies &&  \
    mkdir /home/simulator/temp

RUN mkdir /home/simulator/dependencies/cmake; \
    cd /home/simulator/temp; \
    wget https://cmake.org/files/v3.17/cmake-3.17.1.tar.gz; \
    tar -xvf cmake-3.17.1.tar.gz; \
    cd cmake-3.17.1; \
    mkdir build; \
    cd build; \
    ../configure --prefix="/home/simulator/dependencies/cmake"; \
    make -j8; \
    make install; \
    rm -rf /home/simulator/temp/*

ENV PATH /home/simulator/dependencies/cmake/bin:$PATH

RUN mkdir /home/simulator/dependencies/openmpi &&  \
    cd /home/simulator/temp &&  \
    wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.5.tar.gz &&  \
    tar -xvf openmpi-4.0.5.tar.gz &&  \
    cd openmpi-4.0.5 &&  \
    mkdir build &&  \
    cd build &&  \
    ../configure --prefix=/home/simulator/dependencies/openmpi &&  \
    make -j8 &&  \
    make install &&  \
    rm -rf /home/simulator/temp/*

ENV PATH /home/simulator/dependencies/openmpi/bin:$PATH

ENV LD_LIBRARY_PATH /home/simulator/dependencies/openmpi/lib:$LD_LIBRARY_PATH

RUN mkdir /home/simulator/dependencies/hdf5 &&  \
    cd /home/simulator/temp &&  \
    wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.13/src/hdf5-1.8.13.tar.gz &&  \
    tar -xvf hdf5-1.8.13.tar.gz &&  \
    cd hdf5-1.8.13 &&  \
    mkdir build &&  \
    cd build &&  \
    ../configure --prefix="/home/simulator/dependencies/hdf5" --enable-optimized --enable-shared --enable-cxx --enable-hl --disable-debug &&  \
    make -j8 &&  \
    make install &&  \
    rm -rf /home/simulator/temp/*

ENV PATH /home/simulator/dependencies/hdf5/bin:$PATH 

ENV LD_LIBRARY_PATH /home/simulator/dependencies/hdf5/lib:$LD_LIBRARY_PATH

RUN mkdir /home/simulator/dependencies/swig &&  \
    cd /home/simulator/temp &&  \
    wget -O swig-4.0.0.tar.gz https://sourceforge.net/projects/swig/files/swig/swig-4.0.0/swig-4.0.0.tar.gz/download &&  \
    tar -xvf swig-4.0.0.tar.gz &&  \
    cd swig-4.0.0 &&  \
    mkdir build &&  \
    cd build &&  \
    ../configure --prefix="/home/simulator/dependencies/swig" &&  \
    make -j8 &&  \
    make install &&  \
    rm -rf /home/simulator/temp/*    

ENV PATH /home/simulator/dependencies/swig/bin:$PATH

RUN mkdir /home/simulator/dependencies/boost &&  \
    cd /home/simulator/temp &&  \
    wget -O boost_1_72_0.tar.gz https://sourceforge.net/projects/boost/files/boost/1.72.0/boost_1_72_0.tar.gz/download &&  \
    tar -xvf boost_1_72_0.tar.gz &&  \
    cd boost_1_72_0 &&  \
    ./bootstrap.sh --prefix=/home/simulator/dependencies/boost &&  \
    sed -i "$ a using mpi ;" project-config.jam &&  \
    ./b2 -j8 --prefix=/home/simulator/dependencies/boost -s NO_BZIP2=1 link=shared runtime-link=shared install &&  \
    rm -rf /home/simulator/temp/*

ENV LD_LIBRARY_PATH /home/simulator/dependencies/boost/lib:$LD_LIBRARY_PATH

RUN mkdir /home/simulator/dependencies/moab &&  \
    cd /home/simulator/temp &&  \
    git clone --single-branch -b Version5.1.0 https://bitbucket.org/fathomteam/moab &&  \
    cd moab &&  \
    autoreconf -fi &&  \
    mkdir build &&  \
    cd build &&  \
    ../configure --enable-optimize --enable-shared --disable-debug --with-hdf5=/home/simulator/dependencies/hdf5 --prefix=/home/simulator/dependencies/moab/ &&  \
    make -j8 &&  \
    make install &&  \
    rm -rf /home/simulator/temp/*

ENV PATH /home/simulator/dependencies/moab/bin:$PATH

ENV LD_LIBRARY_PATH /home/simulator/dependencies/moab/lib:$LD_LIBRARY_PATH

RUN mkdir /home/simulator/dependencies/dagmc &&  \
    cd /home/simulator/temp &&  \
    git clone -b amalgamate_py2_fix --single-branch https://github.com/lewisgross1296/DAGMC.git &&  \
    cd DAGMC &&  \
    mkdir build &&  \
    cd build &&  \
    env HDF5_/home/simulator=/home/simulator/dependencies/hdf5 &&  \
    cmake .. -DCMAKE_INSTALL_PREFIX=/home/simulator/dependencies/dagmc \
             -DCMAKE_BUILD_TYPE:STRING=Release \
             -DMOAB_DIR=/home/simulator/dependencies/moab &&  \
    make -j8 &&  \
    make install &&  \
    rm -rf /home/simulator/temp/*

ENV PATH /home/simulator/dependencies/dagmc/bin:$PATH

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/home/simulator/dependencies/dagmc/lib

COPY database.xml /home/simulator/data/database.xml

COPY native /home/simulator/data/native

RUN mkdir /home/simulator/FRENSIE &&  \
    cd /home/simulator/FRENSIE &&  \
    git clone -b start_at_N --single-branch https://github.com/lewisgross1296/FRENSIE.git &&  \
    ln -s FRENSIE src &&  \
    mkdir build &&  \
    cd build &&  \
    cmake -D CMAKE_INSTALL_PREFIX:PATH=/home/simulator/FRENSIE \
          -D CMAKE_BUILD_TYPE:STRING=DEBUG \
          -D CMAKE_VERBOSE_CONFIGURE:BOOL=OFF \
          -D CMAKE_VERBOSE_MAKEFILE:BOOL=ON \
          -D FRENSIE_ENABLE_DBC:BOOL=ON \
          -D FRENSIE_ENABLE_COLOR_OUTPUT:BOOL=ON \
          -D FRENSIE_ENABLE_OPENMP:BOOL=ON \
          -D FRENSIE_ENABLE_MPI:BOOL=ON \
          -D FRENSIE_ENABLE_MOAB:BOOL=ON \
          -D FRENSIE_ENABLE_DAGMC:BOOL=ON \
          -D FRENSIE_ENABLE_ROOT:BOOL=OFF \
          -D FRENSIE_ENABLE_PROFILING:BOOL=OFF \
          -D FRENSIE_ENABLE_COVERAGE:BOOL=OFF \
          -D FRENSIE_ENABLE_EXPLICIT_TEMPLATE_INST:BOOL=ON \
          -D MOAB_PREFIX:PATH=/home/simulator/dependencies/moab \
          -D DAGMC_PREFIX:PATH=/home/simulator/dependencies/dagmc \
          -D HDF5_PREFIX:PATH=/home/simulator/dependencies/hdf5 \
          -D BOOST_PREFIX:PATH=/home/simulator/dependencies/boost \
          -D MPI_PREFIX:PATH=/home/simulator/dependencies/openmpi \
          -D SWIG_PREFIX:PATH=/home/simulator/dependencies/swig \
          -D FRENSIE_ENABLE_DASHBOARD_CLIENT:BOOL=ON \
          /home/simulator/FRENSIE/src &&  \
    make -j8 &&  \
    make install &&  \
    rm -rf /home/simulator/FRENSIE/build &&  \
    rm -rf /home/simulator/FRENSIE/FRENSIE &&  \
    rm -rf /home/simulator/FRENSIE/src 

ENV PATH /home/simulator/FRENSIE/bin:$PATH

ENV PYTHONPATH /home/simulator/FRENSIE/bin:/home/simulator/FRENSIE/lib/python2.7/site-packages

ENV DATABASE_PATH /home/simulator/data/database.xml

RUN rm -rf /home/simulator/temp

RUN chown -R simulator /home/simulator

