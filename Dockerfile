# ---------- build stage ----------
FROM node:20-alpine AS build

# tools needed to build native deps during install
RUN apk add --no-cache git make g++ python3 py3-setuptools

WORKDIR /src
ARG WETTY_REF=main

# grab the source
RUN git clone --depth=1 -b "$WETTY_REF" https://github.com/butlerx/wetty.git
WORKDIR /src/wetty

# use pnpm (via corepack) like upstream
RUN corepack enable && corepack prepare pnpm@latest --activate

# prevent husky's prepare script from running in CI
ENV HUSKY=0

# install deps, build, then drop dev deps
RUN --mount=type=cache,id=pnpm-store,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile && \
    pnpm build && \
    pnpm prune --prod

# ---------- runtime stage ----------
FROM node:20-alpine

# run as non-root
RUN adduser -D -u 10001 wetty
USER wetty
WORKDIR /app

# copy only the built app + production deps
COPY --from=build /src/wetty /app

ENV PORT=3000
EXPOSE 3000

# run wetty directly from the repo's bin
CMD ["node", "/app/bin/wetty.js", "--base", "/", "--port", "3000"]
