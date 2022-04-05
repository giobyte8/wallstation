# This image will setup a cron job to periodicaly sync
# wallpaper collections with local folders

FROM python:3.8-alpine3.15

RUN apk add --no-cache tzdata supercronic bash \
    && apk add yq --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    && pip install gallery-dl

CMD ["supercronic", "/opt/wallstation/downloader/downloader.crontab"]
