# ---------- build stage ----------
FROM node:20-alpine AS build
ARG WETTY_REF=main
ENV HUSKY=0

# tools needed to build native deps
RUN apk add --no-cache git make g++ python3 py3-setuptools

WORKDIR /src
# Grab the latest commit for the chosen ref (branch/tag)
RUN git clone --depth=1 -b "$WETTY_REF" https://github.com/butlerx/wetty.git
WORKDIR /src/wetty

# Use pnpm (via corepack) as upstream does
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install deps, build, then drop dev deps
RUN --mount=type=cache,id=pnpm-store,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile && \
    pnpm build && \
    pnpm prune --prod

# Capture the exact commit we built
RUN git rev-parse HEAD > /src/COMMIT_SHA

# ---------- runtime stage ----------
FROM node:20-alpine

# Non-root
RUN adduser -D -u 10001 wetty
USER wetty
WORKDIR /app

# Copy built artifacts only
COPY --from=build /src/wetty/build             /app/build
COPY --from=build /src/wetty/bin               /app/bin
COPY --from=build /src/wetty/node_modules      /app/node_modules
COPY --from=build /src/wetty/package.json      /app/package.json
COPY --from=build /src/COMMIT_SHA              /app/COMMIT_SHA

# OCI labels (commit & source)
ARG SOURCE_REPO=https://github.com/butlerx/wetty
ARG BUILD_SHA=unknown
LABEL org.opencontainers.image.source=$SOURCE_REPO \
      org.opencontainers.image.revision=$BUILD_SHA

ENV PORT=3000
EXPOSE 3000

# Run WeTTY
CMD ["node", "/app/bin/wetty.js", "--base", "/", "--port", "3000"]
