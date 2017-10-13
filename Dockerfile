FROM debian:stretch
MAINTAINER Andrii Melnyk <kukoban@ukr.net>

# Install basic dependencies
RUN apt-get update -y \
    && apt-get install -y \
        software-properties-common \
        python3-software-properties \
        build-essential \
        python3-dev \
        python3-numpy \
        libpq-dev \
        libcurl4-gnutls-dev \
        libproj-dev \
        libxml2-dev \
        libgeos-dev \
        libnetcdf-dev \
        libpoppler-dev \
        libspatialite-dev \
        libhdf4-alt-dev \
        libhdf5-serial-dev \
        libopenjp2-7-dev \
        wget \
        bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Compile and install GDAL
ENV ROOTDIR /usr/local/
ENV GDAL_DAILY_URL http://www.gdal.org/daily/

# Load assets
WORKDIR $ROOTDIR/

RUN GDAL_DAILY_FL=$(wget -O - $GDAL_DAILY_URL \
    | grep -o '<a href=['"'"'"][^"'"'"']*['"'"'"]' \
    | sed -e 's/^<a href=["'"'"']//' -e 's/["'"'"']$//' \
    | grep -e 'gdal-svn-trunk-[0-9]*.[0-9]*.[0-9]*.tar.gz$') \
    && cd src \
    && wget $GDAL_DAILY_URL$GDAL_DAILY_FL \
    && tar -xvf ${GDAL_DAILY_FL} \
    && cd ${GDAL_DAILY_FL%.tar.gz} \
    && ./configure --with-python --with-curl --with-openjpeg \
    && make && make install && ldconfig \
    && cd $ROOTDIR/src/${GDAL_DAILY_FL%.tar.gz}/swig/python \
    && python3 setup.py build && python3 setup.py install \
    && rm -rf $ROOTDIR/src/* \
    && apt-get update -y \
    && apt-get remove -y --purge build-essential wget \
    && rm -rf /var/lib/apt/lists/*
