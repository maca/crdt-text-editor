defmodule CodeColab.IdStore do
  alias :mnesia, as: Mnesia

  @attributes  [:topic, :replica_id]
  @table Clients

  def init() do
    nodes = [node()]

    Mnesia.create_schema(nodes)
    :ok = Mnesia.start()

    check_table_create(
      Mnesia.create_table(@table,
        [attributes: @attributes, disc_copies: nodes, type: :bag])
    )
  end

  def assign_id(topic) do
    Mnesia.transaction fn ->
      id =
        case topic_ids(topic) do
          [] -> 0
          ids -> Enum.max(ids) + 1
        end

      :ok = Mnesia.write({@table, topic, id})
      id
    end
  end

  defp topic_ids(topic) do
    Mnesia.select @table,
      [{
        {@table, :"$1", :"$2"},
        [ {:==, :"$1", topic} ],
        [:"$2"]
      }]
  end

  defp check_table_create({_, :ok}), do: :ok
  defp check_table_create({_, {:already_exists, _}}), do: :ok
  defp check_table_create(err), do: err
end
