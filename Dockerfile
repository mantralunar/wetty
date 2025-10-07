# --- build stage ---
FROM node:20-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN apk add --no-cache git make g++ python3 py3-setuptools
RUN npm i -g husky@9        # <-- ensures 'husky' is on PATH during 'prepare'
RUN git clone --depth=1 https://github.com/butlerx/wetty.git && cd wetty && pnpm install && pnpm build

# --- runtime stage ---
FROM node:20-alpine AS runtime
RUN adduser -D -u 10001 wetty
WORKDIR /usr/src/app
ENV NODE_ENV=production

# copy what’s actually needed
COPY --from=base ./wetty/node_modules /usr/src/app/node_modules
COPY --from=base ./wetty/build /usr/src/app/build
COPY --from=base ./wetty/package.json /usr/src/app
USER wetty
EXPOSE 3000
CMD [ "pnpm", "start" ]
LABEL org.opencontainers.image.source https://github.com/mantralunar/wetty
