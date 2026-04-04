FROM jekyll/jekyll:4 AS builder

WORKDIR /srv/jekyll

COPY . .

ENV JEKYLL_ENV=production

RUN jekyll build

# -----------------------------

FROM nginx:alpine

COPY --from=builder /srv/jekyll/_site /usr/share/nginx/html
COPY scripts/update-instagram-feed.sh /usr/local/bin/update-instagram-feed.sh
COPY scripts/start-nginx.sh /usr/local/bin/start-nginx.sh

RUN chmod +x /usr/local/bin/update-instagram-feed.sh /usr/local/bin/start-nginx.sh

ENV INSTAGRAM_FEED_PATH=/usr/share/nginx/html/instagram-feed.json

ENTRYPOINT ["/usr/local/bin/start-nginx.sh"]