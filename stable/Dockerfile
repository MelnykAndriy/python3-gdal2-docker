ARG base_img=python:3.7-slim

FROM $base_img as builder

LABEL maintainer="Andrii Melnyk <kukoban@ukr.net>"

ENV ROOTDIR /usr/local/
ARG GDAL_VERSION=2.4.4
ARG OPENJPEG_VERSION=2.3.1

# Load assets
WORKDIR $ROOTDIR/

ADD http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz $ROOTDIR/src/
ADD https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz $ROOTDIR/src/openjpeg-${OPENJPEG_VERSION}.tar.gz

# Install basic dependencies
RUN apt-get update -y && apt-get install -y \
    autoconf \
    automake \
    cmake \
    build-essential \
    libcrypto++-dev \
    libcurl4-gnutls-dev \
    libexpat1-dev \
    libgeos-dev \
    libhdf4-alt-dev \
    libhdf5-serial-dev \
    libjpeg-dev \
    liblzma-dev \
    libnetcdf-dev \
    libopenjp2-7-dev \
    libpoppler-dev \
    libpq-dev \
    libproj-dev \
    libspatialite-dev \
    libssl-dev\
    libwebp-dev \
    libxerces-c-dev \
    libxml2-dev \
    libzstd-dev \
    zip \
    curl \
    software-properties-common \
    sqlite3 

# Install numpy
RUN pip install numpy

# Compile and install OpenJPEG
RUN cd src && tar -xvf openjpeg-${OPENJPEG_VERSION}.tar.gz && rm openjpeg-${OPENJPEG_VERSION}.tar.gz && cd openjpeg-${OPENJPEG_VERSION} \
    && cmake . -DBUILD_SHARED_LIBS=ON  -DBUILD_STATIC_LIBS=OFF -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
    && make -j$(nproc) \
    && make install \
    && mkdir -p /build_thirdparty/usr/lib \
    && cp -P /usr/lib/libopenjp2*.so* /build_thirdparty/usr/lib \
    && for i in /build_thirdparty/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done \
    && cd .. \
    && rm -rf openjpeg-${OPENJPEG_VERSION} 

# Compile and install GDAL
# --with-pg \
#     --with-spatialite \
# --disable-all-optional-drivers \
RUN cd src && tar -xf gdal-${GDAL_VERSION}.tar.gz && cd gdal-${GDAL_VERSION} \
    && ./configure --prefix=/usr \
    --enable-lto \
    --with-cryptopp \
    --with-curl \
    --with-geotiff=internal --with-rename-internal-libgeotiff-symbols \
    --with-hide-internal-symbols \
    --with-libtiff=internal --with-rename-internal-libtiff-symbols \
    --with-openjpeg \
    --with-proj \
    --with-python \
    --with-webp \
    --with-zstd \
    --without-gif \
    --without-gnm \
    --without-lerc \
    --without-libtool \
    --without-pcidsk \
    --without-pcraster \
    && make -j$(nproc) \
    && make install DESTDIR="/build" \
    && cd ../../

RUN cd src/gdal-${GDAL_VERSION}/swig/python \
    && python setup.py build \
    && python setup.py install \
    && cd ../../../ \
    && rm -rf gdal-${GDAL_VERSION} \
    && mkdir -p /build_gdal_python/usr/lib \
    && mkdir -p /build_gdal_python/usr/local/lib \
    && mkdir -p /build_gdal_python/usr/bin \
    && mkdir -p /build_gdal_version_changing/usr/include \
    && mv /build/usr/lib/python3.7          /build_gdal_python/usr/lib \
    && cp -rf /usr/lib/python3.7           /build_gdal_python/usr/lib \
    && cp -rf /usr/local/lib/python3.7     /build_gdal_python/usr/local/lib \
    && mv /build/usr/lib                    /build_gdal_version_changing/usr \
    && mv /build/usr/include/gdal_version.h /build_gdal_version_changing/usr/include \
    && mv /build/usr/bin/*.py               /build_gdal_python/usr/bin \
    && mv /build/usr/bin                    /build_gdal_version_changing/usr \
    && for i in /build_gdal_version_changing/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done \
    && for i in /build_gdal_python/usr/lib/python3.7/dist-packages/osgeo/*.so; do strip -s $i 2>/dev/null || /bin/true; done \
    && for i in /build_gdal_version_changing/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done



FROM $base_img as runner
LABEL maintainer="Andrii Melnyk <kukoban@ukr.net>"

RUN apt-get update -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends \
        g++ \
        gcc \
        gnupg \
        libaec0 \
        libcrypto++6 \
        libcurl4 \
        libexpat1 \
        libgeos-3.7.1 \
        libgeos-c1v5 \
        libhdf4-0-alt \
        libhdf5-103 \
        libhdf5-cpp-103 \
        libjpeg62-turbo \
        libnetcdf13\
        libopenjp2-7 \
        libpq-dev \
        libpq5 \
        libproj-dev \
        libspatialite7 \
        libsqlite3-0 \
        libssl1.1 \
        libtiff5 \
        libwebp6 \
        libxerces-c3.2 \
        libzstd1
# gcc, g++ for compilable libraries such as psycopg2, cython etc.
# libpq is purely for psycopg2
# gnupg is required for stuff like curling from https
# hdf, sqlite, pg, two jpeg drivers are questionable


RUN pip install numpy

# COPY --from=builder  /build_projgrids/usr/ /usr/
COPY --from=builder  /build_thirdparty/usr/ /usr/
# COPY --from=builder  /build_proj/usr/share/proj/ /usr/share/proj/
# COPY --from=builder  /build_proj/usr/include/ /usr/include/
# COPY --from=builder  /build_proj/usr/bin/ /usr/bin/
# COPY --from=builder  /build_proj/usr/lib/ /usr/lib/

COPY --from=builder  /build_gdal_python/usr/ /usr/
COPY --from=builder  /build/usr/share/gdal/ /usr/share/gdal/
COPY --from=builder  /build/usr/include/ /usr/include/
COPY --from=builder  /build_gdal_version_changing/usr/ /usr/
