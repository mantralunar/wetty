FROM node:20-alpine

# Build deps + setuptools shim (for distutils)
RUN apk add --no-cache make g++ python3 py3-setuptools

RUN npm install -g wetty

RUN adduser -D -u 10001 wetty
USER wetty
WORKDIR /home/wetty

ENV PORT=3000
EXPOSE 3000
CMD ["wetty", "--base", "/", "--port", "3000"]
