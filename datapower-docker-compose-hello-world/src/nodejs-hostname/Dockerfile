FROM ubuntu:trusty

COPY src/package.json /srv/www/package.json

RUN apt-get update \
    && apt-get install -y \
        curl \
        nodejs \
        npm \
    && cd /srv/www \
    && npm install

COPY src/index.js /srv/www/

EXPOSE 8080

CMD ["nodejs", "/srv/www/index.js"]
