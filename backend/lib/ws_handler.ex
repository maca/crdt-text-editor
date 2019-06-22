defmodule WsHandler do
  import CodeColab.PubSub
  alias CodeColab.IdStore

  require Logger

  def init(req, _opts) do
    topic = "editor"
    id = IdStore.assign_id(topic)
    {:cowboy_websocket, req, {topic, id}}
  end

  def websocket_init({topic, _} = state) do
    :ok = subscribe(topic)
    {:ok, state}
  end

  def websocket_handle({:text, msg}, {topic, _} = state) do
    IO.puts msg
    broadcast(topic, {:reply, msg})
    {:ok, state}
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def websocket_info({:reply, msg}, state) do
    {:reply, {:text, msg}, state}
  end
end
