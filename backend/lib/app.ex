defmodule CodeColab do
  use Application

  def start(_type, _args) do
    dispatch = :cowboy_router.compile([
      { :_,
        [ { "/ws", WsHandler, [] },
          { "/", :cowboy_static,
            { :priv_file, :codecolab, "static/index.html" }
          },
          { "/[...]", :cowboy_static,
            { :priv_dir, :codecolab, "static" }
          }
        ]
      }
    ])

    { :ok, _ } = :cowboy.start_clear(
      :http, [{ :port, 8080 }], %{env: %{ dispatch: dispatch }}
    )

    # :ok = CodeColab.IdStore.init()
    CodeColab.Supervisor.start_link
  end

  def stop(_state) do
    :ok
  end
end
