# build stage
FROM node:20-alpine AS build
WORKDIR /src
RUN apk add --no-cache git make g++ python3 py3-distutils
RUN corepack enable && corepack prepare pnpm@latest --activate

RUN git clone --depth=1 https://github.com/butlerx/wetty.git
WORKDIR /src/wetty

# prevent "prepare": "husky install" from running
ENV HUSKY=0

RUN --mount=type=cache,id=pnpm-store,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile && \
    pnpm build && \
    pnpm prune --prod

# runtime stage
FROM node:20-alpine
RUN adduser -D -u 10001 wetty
WORKDIR /app
COPY --from=build /src/wetty/build        /app/build
COPY --from=build /src/wetty/server       /app/server
COPY --from=build /src/wetty/package.json /app/package.json
COPY --from=build /src/wetty/node_modules /app/node_modules
ENV NODE_ENV=production PORT=3000
EXPOSE 3000
USER wetty
CMD ["node", "server/index.js"]
