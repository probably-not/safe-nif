defmodule SafeNIF.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [{SafeNIF, name: SafeNIF.Pool.default_pool_name()}]
    opts = [strategy: :one_for_one, name: SafeNIF.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
