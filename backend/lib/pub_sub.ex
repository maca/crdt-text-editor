defmodule CodeColab.PubSub do
  def subscribe(topic) do
    Phoenix.PubSub.subscribe __MODULE__, topic
  end

  def broadcast_all(topic, message) do
    Phoenix.PubSub.broadcast! __MODULE__, topic, message
  end

  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast_from! __MODULE__, self(),
      topic, message
  end
end
