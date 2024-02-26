# syntax=docker/dockerfile:1
FROM registry.hub.docker.com/oven/bun:1.0.29 AS bun

FROM bun AS build

WORKDIR /build

COPY ./package.json ./bun.lockb /build/
RUN bun install --frozen-lockfile

COPY . /build
RUN bun run build


FROM bun AS deps

WORKDIR /deps

COPY ./package.json ./bun.lockb /deps/
RUN bun install --frozen-lockfile --production


FROM gcr.io/distroless/base-nossl-debian12:latest

COPY --from=bun /usr/local/bin/bun /

WORKDIR /app

COPY --from=deps /deps/node_modules /app/node_modules
COPY --from=build /build/dist /app

USER nonroot:nonroot

ENTRYPOINT ["/bun"]
CMD ["./index.js"]
