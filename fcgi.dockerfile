FROM nginx:stable

RUN mkdir -p /usr/local/share/httpoxy
WORKDIR /usr/local/share/httpoxy

RUN rm -rf /etc/nginx/conf.d/*
COPY nginx.conf /etc/nginx/nginx.conf

COPY fcgi ./httpoxy

CMD /bin/bash -c "/usr/local/share/httpoxy/httpoxy & nginx -g 'daemon off;'"
