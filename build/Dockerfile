FROM node:13
RUN apt-get update -y
RUN apt-get install nginx -y
RUN apt-get install -y gettext
RUN apt-get install -y perl
RUN apt-get install -y cpanminus
COPY default.conf.template /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY codecert /etc/nginx/conf.d/codecert
COPY www /usr/share/nginx/html/www
RUN mkdir /usr/src/app
RUN mkdir /usr/src/tempapp
COPY . /usr/src/tempapp/
RUN cd /usr/src/tempapp/crawler
RUN cpanm -v utf8::all
RUN cpanm -v HTTP::Tiny
RUN cpanm -v HTML::Restrict
RUN cpanm -v Mojolicious
RUN cpanm -v Mojo::CSV
RUN cpanm -v WWW::Crawler::Mojo
RUN prove -lr t
RUN tar -xvzf /usr/src/tempapp/api.tar.gz -C /usr/src/app/
RUN npm install pm2 -g
ENV PM2_PUBLIC_KEY yvrvn72bu2lkm32
ENV PM2_SECRET_KEY boiau4bbtmgggow
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN pm2 link u4rh5ruhn1xdgo3 vqag8k3mdn0nnlh
RUN cd /usr/src/app/bundle/programs/server && npm install



CMD ["sh", "-c", "nginx && morbo -l 'http://*:3200' ./dataService && pm2-runtime start /usr/src/tempapp/ecosystem.config.js --env $env_name"]