# syntax=docker/dockerfile:1

# ref: https://github.com/oven-sh/bun/blob/639a12f59fc5342360c341bc9858244c107cc30e/dockerhub/Dockerfile-distroless
FROM debian:bookworm-slim AS bun

# https://github.com/oven-sh/bun/releases
ARG BUN_VERSION=latest

RUN apt-get update -qq \
  && apt-get install -qq --no-install-recommends \
  ca-certificates \
  curl \
  dirmngr \
  gpg \
  gpg-agent \
  unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && arch="$(dpkg --print-architecture)" \
  && case "${arch##*-}" in \
  amd64) build="x64-baseline";; \
  arm64) build="aarch64";; \
  *) echo "error: unsupported architecture: ($arch)"; exit 1 ;; \
  esac \
  && version="$BUN_VERSION" \
  && case "$version" in \
  latest | canary | bun-v*) tag="$version"; ;; \
  v*)                       tag="bun-$version"; ;; \
  *)                        tag="bun-v$version"; ;; \
  esac \
  && case "$tag" in \
  latest) release="latest/download"; ;; \
  *)      release="download/$tag"; ;; \
  esac \
  && curl "https://github.com/oven-sh/bun/releases/$release/bun-linux-$build.zip" \
  -fsSLO \
  --compressed \
  --retry 5 \
  || (echo "error: unknown release: ($tag)" && exit 1) \
  && for key in \
  "F3DCC08A8572C0749B3E18888EAB4D40A7B22B59" \
  ; do \
  gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" \
  || gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && gpg --update-trustdb \
  && curl "https://github.com/oven-sh/bun/releases/$release/SHASUMS256.txt.asc" \
  -fsSLO \
  --compressed \
  --retry 5 \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  || (echo "error: failed to verify release: ($tag)" && exit 1) \
  && grep " bun-linux-$build.zip\$" SHASUMS256.txt | sha256sum -c - \
  || (echo "error: failed to verify release: ($tag)" && exit 1) \
  && unzip "bun-linux-$build.zip" \
  && mv "bun-linux-$build/bun" /usr/local/bin/bun \
  && rm -f "bun-linux-$build.zip" SHASUMS256.txt.asc SHASUMS256.txt \
  && chmod +x /usr/local/bin/bun \
  && ln -s /usr/local/bin/bun /usr/local/bin/bunx \
  && which bun \
  && which bunx \
  && bun --version


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


FROM gcr.io/distroless/base-nossl-debian12

COPY --from=bun /usr/local/bin/bun /

WORKDIR /app

COPY --from=deps /deps/node_modules /app/node_modules
COPY --from=build /build/dist/index.js /app

USER nonroot:nonroot

ENTRYPOINT ["/bun"]
CMD ["./index.js"]
