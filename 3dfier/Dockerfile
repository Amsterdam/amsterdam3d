FROM pdal/pdal:latest
MAINTAINER datapunt.ois@amsterdam.nl

RUN apt-get update \
	&& apt-get install -y \
		netcat \
		wget \
		git \
		build-essential \
 	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

WORKDIR /temp
RUN wget http://download.osgeo.org/liblas/libLAS-1.8.1.tar.bz2
RUN tar -xvf libLAS-1.8.1.tar.bz2

WORKDIR /temp/libLAS-1.8.1
RUN mkdir build

# Twice, according to readme.md
WORKDIR /temp/libLAS-1.8.1/build
RUN cmake -G "Unix Makefiles" ..

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

#WORKDIR /temp/
#RUN rm -rf /temp/3dfier
#
# Prepare for piplinescripts
RUN apt-get update \
	&& apt-get install -y \
		nodejs \
		npm \
 	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PATH="/temp/3dfier/build:${PATH}"
WORKDIR /temp/3dfier/example_data
