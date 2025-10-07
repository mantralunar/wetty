# --- build stage ---
FROM node:20-alpine AS build
WORKDIR /src
RUN apk add --no-cache git make g++ python3 py3-setuptools

# build stage (snippet)
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN npm i -g husky@9        # <-- ensures 'husky' is on PATH during 'prepare'
RUN git clone --depth=1 https://github.com/butlerx/wetty.git
WORKDIR /src/wetty

RUN --mount=type=cache,id=pnpm-store,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile && \
    pnpm build && \
    pnpm prune --prod


# --- runtime stage ---
FROM node:20-alpine AS runtime
RUN adduser -D -u 10001 wetty

# runtime stage
WORKDIR /app
COPY --from=build /src/wetty/build         /app/build
COPY --from=build /src/wetty/node_modules  /app/node_modules
COPY --from=build /src/wetty/package.json  /app/package.json

USER wetty
EXPOSE 3000
# wetty’s CLI entry lives in bin/
CMD ["node","/app/bin/wetty.js","--port","3000"]
