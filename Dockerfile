# ---------- build stage ----------
FROM node:20-alpine AS build
ARG WETTY_REF=main

# Native build deps for node-pty/gc-stats, plus git
RUN apk add --no-cache git make g++ python3 py3-setuptools

WORKDIR /src
# Grab latest commit on the chosen ref
RUN git clone --depth=1 -b "$WETTY_REF" https://github.com/butlerx/wetty.git
WORKDIR /src/wetty

# Package manager setup and Husky available on PATH for lifecycle scripts
RUN corepack enable && corepack prepare pnpm@latest --activate && npm i -g husky

# Install deps (scripts enabled so native addons build & husky prepare works), build, then prune
RUN --mount=type=cache,id=pnpm-store,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile && \
    pnpm build && \
    pnpm prune --prod --ignore-scripts

# Record exact upstream commit
RUN git rev-parse HEAD > /src/COMMIT_SHA

# ---------- runtime stage ----------
FROM node:20-alpine

# Non-root runtime user
RUN adduser -D -u 10001 wetty
USER wetty
WORKDIR /app

# Copy only what’s needed
COPY --from=build /src/wetty/build        /app/build
COPY --from=build /src/wetty/bin          /app/bin
COPY --from=build /src/wetty/node_modules /app/node_modules
COPY --from=build /src/wetty/package.json /app/package.json
COPY --from=build /src/COMMIT_SHA         /app/COMMIT_SHA

ENV PORT=3000
EXPOSE 3000

CMD ["node", "/app/bin/wetty.js", "--base", "/", "--port", "3000"]
