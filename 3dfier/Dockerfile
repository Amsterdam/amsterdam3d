FROM pdal/pdal:latest
MAINTAINER datapunt.ois@amsterdam.nl

RUN apt-get update \
	&& apt-get install -y \
		postgresql-server-dev-9.5 \
		netcat \
		wget \
		git \
		subversion \
		build-essential \
		autoconf \
		libtool \
		libsqlite3-dev \
		libspatialite7 \
 	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# build GEOS
WORKDIR /temp
RUN mkdir geos

WORKDIR /temp/geos
RUN svn checkout -q https://svn.osgeo.org/geos/tags/3.6.1/

WORKDIR /temp/geos/3.6.1
RUN ./autogen.sh

WORKDIR /temp/geos/3.6.1
RUN ./configure

WORKDIR /temp/geos/3.6.1
RUN make -j 4

WORKDIR /temp/geos/3.6.1
RUN make install

RUN rm -rf /temp/geos

# Install recent GDAL
WORKDIR /temp
RUN git clone https://github.com/OSGeo/gdal.git

WORKDIR /temp/gdal
RUN git checkout tags/2.1.3

WORKDIR /temp/gdal/gdal
RUN ./configure

WORKDIR /temp/gdal/gdal
RUN make -j 4

WORKDIR /temp/gdal/gdal
RUN make install

WORKDIR /temp
RUN rm -rf /temp/gdal

#Install 3dfier
RUN apt-get update \
	&& apt-get install -y \
		cmake \
		libboost-all-dev \
		libgeotiff-dev \
 	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /temp
RUN wget https://github.com/LASzip/LASzip/releases/download/v2.2.0/laszip-src-2.2.0.tar.gz
RUN tar -xvf laszip-src-2.2.0.tar.gz

WORKDIR /temp/laszip-src-2.2.0
RUN ./configure

WORKDIR /temp/laszip-src-2.2.0
RUN make -j 4

WORKDIR /temp/laszip-src-2.2.0
RUN make install

WORKDIR /temp
RUN rm -rf /temp/laszip-src-2.2.0

# Circumventing https://github.com/libLAS/libLAS/issues/9
WORKDIR /usr/local/include
RUN mkdir laszip

WORKDIR /usr/local/include/laszip
RUN ln -s ../laszip.hpp laszip.hpp

WORKDIR /temp
RUN wget http://download.osgeo.org/liblas/libLAS-1.8.1.tar.bz2
RUN tar -xvf libLAS-1.8.1.tar.bz2

WORKDIR /temp/libLAS-1.8.1
RUN mkdir build

WORKDIR /temp/libLAS-1.8.1/build
RUN cmake -G "Unix Makefiles" -DWITH_LASZIP=true -DLASZIP_INCLUDE_DIR=/usr/local/include ..

WORKDIR /temp/libLAS-1.8.1/build
RUN make -j 4

WORKDIR /temp/libLAS-1.8.1/build
RUN make install

WORKDIR /temp/
RUN rm -rf /temp/libLAS-1.8.1

#Install 3dfier
RUN apt-get update \
	&& apt-get install -y \
		libyaml-cpp-dev \
		libcgal-dev \
		libcgal-qt5-dev \
		libcgal-qt5-11 \
 	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN ldconfig

WORKDIR /temp
RUN git clone https://github.com/tudelft3d/3dfier

WORKDIR /temp/3dfier
RUN git checkout v0.9.5

WORKDIR /temp/3dfier
RUN mkdir build

# Twice, according to readme.md
WORKDIR /temp/3dfier/build
RUN cmake .. -DLIBLAS_LIBRARY=/usr/local/lib/liblas.so
RUN cmake .. -DLIBLAS_LIBRARY=/usr/local/lib/liblas.so

WORKDIR /temp/3dfier/build
RUN make -j 4

RUN mkdir /work
RUN mkdir /output
RUN cp 3dfier /work
RUN mv /temp/3dfier/example_data/* /work

WORKDIR /temp/
RUN rm -rf /temp/3dfier

# Prepare for piplinescripts
RUN curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
RUN apt-get install -y nodejs

ENV PATH="/work:${PATH}"
WORKDIR /work

WORKDIR /tiles/
RUN git clone https://github.com/geodan/3dfier-tiles

WORKDIR /tiles/3dfier-tiles
RUN npm install -g
RUN npm run build

COPY pdal_options* /tiles/3dfier-tiles/conf/
COPY 3dfier.yml /tiles/3dfier-tiles/conf/
COPY worker.js /tiles/3dfier-tiles/src/worker.js
COPY run* /tiles/3dfier-tiles/src/
RUN chmod +x /tiles/3dfier-tiles/src/run3dfier.sh

WORKDIR /tiles/3dfier-tiles

