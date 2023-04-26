FROM jekyll/builder:3.8 AS builder

RUN mkdir /app && chown -R jekyll:jekyll /app

WORKDIR /app

COPY . .

ENV JEKYLL_ENV=production \
    JEKYLL_GID=1000 \
    JEKYLL_UID=1000
RUN jekyll build 

FROM nginx
COPY --from=builder /app/_site /usr/share/nginx/html