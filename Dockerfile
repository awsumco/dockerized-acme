FROM nginx:alpine

LABEL maintainer "awsumco <awsumco@users.noreply.github.com>"

RUN apk upgrade --no-cache \
  && apk add --update --no-cache \
  vim \
  bash \
  curl \
  openssl \
  bind-tools \
  jq \
  tini \
  tzdata \
  python3 \
  && python3 -m pip install --upgrade pip \
  && python3 -m pip install acme-tiny

COPY acme_start.sh /srv/acme_start.sh
COPY acme_run.sh /srv/acme_run.sh
COPY default.conf /etc/nginx/conf.d/default.conf
# COPY tiny-web.py /srv/tiny-web.py

RUN chmod +x /srv/*.sh

CMD ["/sbin/tini", "-g", "--", "/srv/acme_start.sh"]
