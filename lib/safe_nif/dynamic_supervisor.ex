defmodule SafeNIF.DynamicSupervisor do
  @moduledoc false
  use DynamicSupervisor

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: opts[:name])
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def count do
    __MODULE__
    |> DynamicSupervisor.count_children()
    |> tap(fn counts ->
      :telemetry.execute([:safe_nif, :supervisor], counts)
    end)
  end
end
