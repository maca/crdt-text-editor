defmodule CodeColab.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {Phoenix.PubSub.PG2, name: CodeColab.PubSub}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
