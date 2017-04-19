FROM nginx:latest
MAINTAINER datapunt.ois@amsterdam.nl

# Prepare for viewer scripts
RUN apt-get update \
	&& apt-get install -y \
		nodejs \
		nodejs-legacy \
		npm \
 	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install viewer scripts
RUN apt-get update \
	&& apt-get install -y \
		git \
 	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /services

WORKDIR /services
RUN git clone https://github.com/Geodan/x3d_services.git

WORKDIR /services/x3d_services
RUN npm install

RUN mkdir /app

WORKDIR /app
RUN git clone https://github.com/Geodan/x3d_viewer.git

WORKDIR /app/x3d_viewer
RUN npm install -g bower
RUN bower install --allow-root
COPY app/amsterdam* /services/x3d_services/js/

WORKDIR /temp
RUN git clone https://github.com/AnalyticalGraphicsInc/cesium

WORKDIR /temp/cesium
RUN git checkout 3d-tiles

WORKDIR /temp/cesium
RUN npm run combineRelease

# /var/www/html/

EXPOSE 80

RUN apt-get update \
    && apt-get install -y \
            curl \
            netcat-openbsd \
    && apt-get clean \
    && rm -rf /var/cache/apt

COPY default.conf /etc/nginx/conf.d/

WORKDIR /services/x3d_services/js
CMD node amsterdam_service.js && node amsterdam_ahn3_service.js && nginx -g daemon off
