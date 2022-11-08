FROM alpine:3.14

RUN set -ex && apk --no-cache add sudo

RUN sudo apk update
RUN sudo apk add git
RUN apk add --update nodejs npm

RUN wget https://github.com/gohugoio/hugo/releases/download/v0.105.0/hugo_0.105.0_linux-amd64.tar.gz
RUN tar -zxvf hugo_0.105.0_linux-amd64.tar.gz
