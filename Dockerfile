FROM elixir:1.19.5-otp-28-bookworm AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git curl && \
    rm -rf /var/lib/apt/lists/*

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

FROM debian:bookworm-slim AS runner

RUN apt-get update && \
    apt-get install -y --no-install-recommends libstdc++6 openssl libncurses6 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV LANG=C.UTF-8
ENV MIX_ENV=prod

COPY --from=builder /app/_build/prod/rel/bankas_2026_backend ./

EXPOSE 4000

CMD ["/app/bin/bankas_2026_backend", "start"]
