FROM jekyll/builder:3.8 AS builder
WORKDIR /srv/jekyll
COPY . .
ENV JEKYLL_ENV=production \
    JEKYLL_GID=1000 \
    JEKYLL_UID=1000
RUN jekyll build && mv _site _site_build

FROM nginx
COPY --from=builder /srv/jekyll/_site_build /usr/share/nginx/html
