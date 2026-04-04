FROM jekyll/builder:4 AS builder

RUN mkdir /app && chown -R jekyll:jekyll /app

WORKDIR /app

COPY . .

ENV JEKYLL_ENV=production \
    JEKYLL_GID=1000 \
    JEKYLL_UID=1000
RUN jekyll build 

FROM nginx:alpine

COPY --from=builder /app/_site /usr/share/nginx/html
COPY scripts/update-instagram-feed.sh /usr/local/bin/update-instagram-feed.sh
COPY scripts/start-nginx.sh /usr/local/bin/start-nginx.sh

RUN chmod +x /usr/local/bin/update-instagram-feed.sh /usr/local/bin/start-nginx.sh

ENV INSTAGRAM_FEED_PATH=/usr/share/nginx/html/instagram-feed.json

ENTRYPOINT ["/usr/local/bin/start-nginx.sh"]