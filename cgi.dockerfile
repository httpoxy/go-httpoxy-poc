FROM eboraas/apache:latest

RUN mkdir -p /usr/local/share/httpoxy
WORKDIR /usr/local/share/httpoxy

COPY cgi .
