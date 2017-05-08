FROM node:latest
MAINTAINER datapunt.ois@amsterdam.nl

# Prepare for viewer scripts
RUN apt-get update \
	&& apt-get install -y \
		git \
		npm \
 	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Make node command available as symlink to nodejs
#RUN ln -s /usr/bin/nodejs /usr/bin/node
#
RUN mkdir /viewer
WORKDIR /viewer
RUN git clone https://github.com/AnalyticalGraphicsInc/cesium

WORKDIR /viewer/cesium
RUN git checkout 3d-tiles

RUN npm install
RUN npm run minifyRelease

#RUN mkdir /var/www
#RUN mkdir /var/www/html
#RUN ln -s /app/x3d_viewer/ /var/www/html/x3d
#
#EXPOSE 80

