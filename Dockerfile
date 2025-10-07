# ---------- build stage ----------
FROM node:20-alpine AS build
ARG WETTY_REF=main

# Needed for native addons
RUN apk add --no-cache git make g++ python3 py3-setuptools

WORKDIR /src
RUN git clone --depth=1 -b "$WETTY_REF" https://github.com/butlerx/wetty.git
WORKDIR /src/wetty

# Use pnpm (via corepack)
RUN corepack enable && corepack prepare pnpm@latest --activate

# Don't let husky run in CI
ENV HUSKY=0

# 1) install with scripts (build native deps)
# 2) build
# 3) prune prod deps, but SKIP lifecycle scripts so husky can't rerun
RUN --mount=type=cache,id=pnpm-store,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile && \
    pnpm build && \
    PNPM_SKIP_LIFECYCLE_SCRIPTS=1 pnpm prune --prod

# record exact upstream commit
RUN git rev-parse HEAD > /src/COMMIT_SHA

# ---------- runtime stage ----------
FROM node:20-alpine

# non-root
RUN adduser -D -u 10001 wetty
USER wetty
WORKDIR /app

# copy only what we need
COPY --from=build /src/wetty/build        /app/build
COPY --from=build /src/wetty/bin          /app/bin
COPY --from=build /src/wetty/node_modules /app/node_modules
COPY --from=build /src/wetty/package.json /app/package.json
COPY --from=build /src/COMMIT_SHA         /app/COMMIT_SHA

ENV PORT=3000
EXPOSE 3000

CMD ["node", "/app/bin/wetty.js", "--base", "/", "--port", "3000"]
