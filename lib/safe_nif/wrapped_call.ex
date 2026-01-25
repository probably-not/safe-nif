defmodule SafeNIF.WrappedCall do
  @moduledoc false

  def call(pid, fun) when is_function(fun, 0) do
    fn ->
      result = fun.()
      send(pid, {:ok, result})
    end
  end

  def call(pid, {mod, fun, args}) when is_atom(mod) and is_list(args) and is_function(fun, length(args)) do
    {__MODULE__, :wrapped, [pid, mod, fun, args]}
  end

  @doc false
  def wrapped(pid, mod, fun, args) when is_atom(mod) and is_list(args) and is_function(fun, length(args)) do
    result = apply(mod, fun, args)
    send(pid, {:ok, result})
  end
end
