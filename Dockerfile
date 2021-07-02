FROM perrygeo/gdal-base:latest as builder

RUN apt-get update
RUN apt-get install -y --no-install-recommends automake libtool

ENV CPUS 8

ENV EXPAT_VER=2.2.0
RUN wget https://github.com/libexpat/libexpat/archive/R_2_2_0.tar.gz \
    && tar xvfz R_2_2_0.tar.gz \
    && mv libexpat-R_2_2_0 expat-${EXPAT_VER} \
    && cd expat-${EXPAT_VER}/expat \
    && sh buildconf.sh \
    && ./configure --prefix=/usr/local \
    && make --quiet -j${CPUS} && make --quiet install --ignore-errors

# Rebuild GDAL
RUN cd gdal-${GDAL_SHORT_VERSION} && \
    ./configure \
    --disable-debug \
    --prefix=/usr/local \
    --disable-static \
    --with-curl=/usr/local/bin/curl-config \
    --with-geos \
    --with-hide-internal-symbols=yes \
    --with-png \
    --with-openjpeg \
    --with-sqlite3 \
    --with-proj=/usr/local \
    --with-rename-internal-libgeotiff-symbols=yes \
    --with-rename-internal-libtiff-symbols=yes \
    --with-threads=yes \
    --with-webp=/usr/local \
    --with-zstd=/usr/local \
    --with-libdeflate \
    --with-geotiff=/usr/local \
    --with-libtiff=/usr/local \
    --with-jpeg=/usr/local \
    --with-expat=/usr/local \
    && echo "building GDAL ${GDAL_VERSION}..." \
    && make -j${CPUS} clean && make --quiet install

# ------ Second stage
# Start from a clean image
FROM python:3.8-slim-buster as final

# Install some required runtime libraries from apt
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        libfreexl1 libxml2 \
    && rm -rf /var/lib/apt/lists/*

# Install the previously-built shared libaries from the builder image
COPY --from=builder /usr/local /usr/local
RUN ldconfig
