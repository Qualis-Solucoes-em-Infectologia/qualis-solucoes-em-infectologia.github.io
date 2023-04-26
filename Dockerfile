FROM jekyll/builder:3.8 as builder

COPY . .
ENV JEKYLL_ENV=production
ENV JEKYLL_ROOTLESS=1
RUN jekyll build

FROM nginx
COPY --from=builder /srv/jekyll/_site /usr/share/nginx/html