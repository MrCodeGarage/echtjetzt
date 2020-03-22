FROM node:13
RUN apt-get update -y
RUN apt-get install nginx -y
RUN apt-get install -y gettext
RUN apt-get install -y perl
RUN apt-get install -y cpanminus
RUN apt-get install -y python
COPY default.conf.template /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY codecert /etc/nginx/conf.d/codecert
COPY www /usr/share/nginx/html/www
RUN mkdir /usr/src/app
RUN mkdir /usr/src/tempapp
COPY . /usr/src/tempapp/
RUN cd /usr/src/tempapp/crawler && cpanm -v utf8::all
RUN cd /usr/src/tempapp/crawler && cpanm -v HTTP::Tiny
RUN cd /usr/src/tempapp/crawler && cpanm -v HTML::Restrict
RUN cd /usr/src/tempapp/crawler && cpanm -v Mojolicious
RUN cd /usr/src/tempapp/crawler && cpanm -v Mojo::CSV
RUN cd /usr/src/tempapp/crawler && cpanm -v WWW::Crawler::Mojo
RUN cd /usr/src/tempapp/crawler && cpanm -v MongoDB
RUN cd /usr/src/tempapp/crawler && prove -lr t
RUN cd /usr/src/tempapp/python && pip install -r requirement.txt
RUN tar -xvzf /usr/src/tempapp/api.tar.gz -C /usr/src/app/
RUN npm install pm2 -g
ENV PM2_PUBLIC_KEY yvrvn72bu2lkm32
ENV PM2_SECRET_KEY boiau4bbtmgggow
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN pm2 link u4rh5ruhn1xdgo3 vqag8k3mdn0nnlh
RUN cd /usr/src/app/bundle/programs/server && npm install


CMD ["sh", "-c", "nginx  && pm2-runtime start /usr/src/tempapp/ecosystem.config.js --env $env_name"]