FROM jekyll/builder:3.8 AS builder

RUN id -u jekyll || (groupadd -r jekyll && useradd -r -g jekyll jekyll)

RUN mkdir /app && chown -R jekyll:jekyll /app

WORKDIR /app

COPY . .

ENV JEKYLL_ENV=production \
    JEKYLL_GID=1000 \
    JEKYLL_UID=1000
RUN jekyll build 

FROM nginx
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl jq ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/_site /usr/share/nginx/html
COPY scripts/update-instagram-feed.sh /usr/local/bin/update-instagram-feed.sh
COPY scripts/start-nginx.sh /usr/local/bin/start-nginx.sh

RUN chmod +x /usr/local/bin/update-instagram-feed.sh /usr/local/bin/start-nginx.sh

ENV INSTAGRAM_FEED_PATH=/usr/share/nginx/html/instagram-feed.json

ENTRYPOINT ["/usr/local/bin/start-nginx.sh"]