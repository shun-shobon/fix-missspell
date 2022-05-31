FROM denoland/deno:1.22.1 AS build

WORKDIR /build

COPY deps.ts ./
RUN deno cache deps.ts

COPY . ./
RUN deno compile --unstable --output=app --allow-net=discord.com,gateway.discord.gg --allow-env=DISCORD_TOKEN mod.ts
RUN chmod 755 app


FROM gcr.io/distroless/cc

WORKDIR /app

USER nonroot

COPY --from=build /build/app ./

CMD ["./app"]
