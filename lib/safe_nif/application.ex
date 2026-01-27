defmodule SafeNIF.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [SafeNIF.Pool]
    opts = [strategy: :one_for_one, name: SafeNIF.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
