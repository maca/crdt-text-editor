FROM codesimple/elm:0.19

ENV APP_HOME /app/

WORKDIR $APP_HOME

RUN apk update && \
  apk add --no-cache yarn && \
  yarn global add elm-test && \
  yarn global add elm-live


ADD . $APP_HOME
