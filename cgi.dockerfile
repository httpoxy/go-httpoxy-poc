FROM eboraas/apache:latest

RUN mkdir -p /usr/local/share/httpoxy
WORKDIR /usr/local/share/httpoxy

RUN a2enmod cgid
COPY apache2.conf /etc/apache2/apache2.conf

COPY cgi ./httpoxy
