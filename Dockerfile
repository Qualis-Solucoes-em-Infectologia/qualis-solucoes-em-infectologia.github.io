FROM jekyll/builder:3.8 AS builder
WORKDIR /srv/jekyll
COPY . .
ENV JEKYLL_ENV=production \
    JEKYLL_GID=1000 \
    JEKYLL_UID=1000
RUN jekyll build && ls -lah

FROM nginx
COPY --from=builder /srv/jekyll/_site /usr/share/nginx/html
