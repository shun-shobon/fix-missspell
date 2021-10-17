FROM denoland/deno AS build

WORKDIR /build

COPY deps.ts ./
RUN deno cache deps.ts

COPY . ./
RUN deno bundle mod.ts mod.js


FROM denoland/deno:distroless

WORKDIR /app

COPY --from=build /build/mod.js ./

CMD ["run", "--allow-net=discord.com,gateway.discord.gg", "--allow-env", "--allow-read=.env,.env.example,.env.defaults", "mod.js"]
