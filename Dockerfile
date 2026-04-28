FROM elixir:1.19.5-otp-28-alpine AS builder

RUN apk add --no-cache build-base git curl

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config

RUN mix deps.get --only prod
RUN mix deps.compile

COPY priv priv
COPY assets assets
COPY lib lib

RUN mix compile
RUN mix assets.deploy
RUN mix release

FROM alpine:3.22 AS runner

RUN apk add --no-cache libstdc++ openssl ncurses-libs ca-certificates

WORKDIR /app

ENV LANG=C.UTF-8
ENV MIX_ENV=prod

COPY --from=builder /app/_build/prod/rel/bankas_2026_backend ./

EXPOSE 4000

CMD ["/app/bin/bankas_2026_backend", "start"]
