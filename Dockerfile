FROM jekyll/builder:3.8 as builder
#RUN mkdir app
COPY . .
ENV JEKYLL_ENV=production
# ENV JEKYLL_UID=1000
# ENV JEKYLL_GID=1000
RUN jekyll build
RUN ls -lah

FROM nginx
COPY --from=builder /srv/jekyll/_site /usr/share/nginx/html