FROM alpine:latest

RUN apk update

RUN apk add git

WORKDIR /app

COPY ./docker/ /app/

RUN chmod +x script.sh

CMD ["sh", "./script.sh"]
