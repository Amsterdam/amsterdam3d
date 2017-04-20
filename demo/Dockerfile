FROM nginx:latest
MAINTAINER datapunt.ois@amsterdam.nl

# Prepare for viewer scripts
RUN apt-get update \
	&& apt-get install -y \
		nodejs \
		nodejs-legacy \
		git \
		npm \
 	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /services

WORKDIR /services
RUN git clone https://github.com/Geodan/x3d_services.git

WORKDIR /services/x3d_services
RUN npm install
COPY app/amsterdam* /services/x3d_services/js/

RUN mkdir /app

WORKDIR /app
RUN git clone https://github.com/Geodan/x3d_viewer.git

WORKDIR /app/x3d_viewer
RUN npm install -g bower
RUN bower install --allow-root
RUN mkdir /var/www
RUN mkdir /var/www/html
RUN ln -s /app/x3d_viewer/ /var/www/html/x3d

EXPOSE 80

RUN apt-get update \
    && apt-get install -y \
            curl \
            netcat-openbsd \
    && apt-get clean \
    && rm -rf /var/cache/apt

COPY default.conf /etc/nginx/conf.d/

RUN npm install -g forever
RUN npm install -g forever-service

WORKDIR /services/x3d_services/js
RUN forever-service install adam_pointcloud --script amsterdam_service.js
RUN forever-service install ahn3_pointcloud --script amsterdam_ahn3_service.js

RUN service adam_pointcloud start
RUN service ahn3_pointcloud start

COPY adam_conf.js /app/x3d_viewer/conf/adam_conf.js
