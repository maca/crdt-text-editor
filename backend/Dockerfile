FROM elixir:1.11-alpine

ENV APP_HOME /app/

WORKDIR $APP_HOME
COPY . $APP_HOME

RUN mix local.rebar && mix local.hex --force && \
      mix do deps.get, compile
