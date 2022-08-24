ARG MIX_ENV="prod"

FROM hexpm/elixir:1.13.3-erlang-24.2.1-alpine-3.15.0 AS build

# install build dependencies
RUN apk add --update --no-cache build-base git python3 curl

# add glibc in order to use dart-sass
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.33-r0/glibc-2.33-r0.apk
RUN apk add glibc-2.33-r0.apk

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ARG MIX_ENV
ENV MIX_ENV="${MIX_ENV}"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

# copy compile configuration files
RUN mkdir config
COPY config/config.exs config/$MIX_ENV.exs config/

# compile dependencies
RUN mix deps.compile

# copy assets
COPY priv priv
COPY assets assets

# Compile assets
RUN mix assets.deploy

# compile and build release
COPY lib lib
RUN mix do compile

# copy runtime configuration file
COPY config/runtime.exs config/

# assemble release
RUN mix release

# prepare release image
FROM alpine:3.13.6 AS app
RUN apk upgrade --no-cache && \
    apk add --no-cache bash openssl libgcc libstdc++ ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/shuttertop ./

EXPOSE 8080

ENV HOME=/app
ENV PORT=8080

CMD ["bin/shuttertop", "start"]
