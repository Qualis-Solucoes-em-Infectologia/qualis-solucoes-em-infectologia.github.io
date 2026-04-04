FROM ruby:3.2-alpine AS builder

RUN apk add --no-cache build-base gcc cmake git

WORKDIR /app

# instala jekyll e bundler
RUN gem install jekyll bundler

COPY . .

RUN bundle install || true
RUN jekyll build

# -----------------------------

FROM nginx:alpine

COPY --from=builder /app/_site /usr/share/nginx/html
COPY scripts/update-instagram-feed.sh /usr/local/bin/update-instagram-feed.sh
COPY scripts/start-nginx.sh /usr/local/bin/start-nginx.sh

RUN chmod +x /usr/local/bin/update-instagram-feed.sh /usr/local/bin/start-nginx.sh

ENV INSTAGRAM_FEED_PATH=/usr/share/nginx/html/instagram-feed.json

ENTRYPOINT ["/usr/local/bin/start-nginx.sh"]
