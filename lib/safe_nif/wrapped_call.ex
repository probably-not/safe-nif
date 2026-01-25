defmodule SafeNIF.WrappedCall do
  @moduledoc false

  def call(pid, fun) when is_function(fun, 0) do
    fn ->
      result = fun.()
      send(pid, {:ok, result})
    end
  end

  def call(pid, {mod, fun, args}) when is_atom(mod) and is_atom(fun) and is_list(args) do
    {__MODULE__, :wrapped, [pid, mod, fun, args]}
  end

  @doc false
  def wrapped(pid, mod, fun, args) when is_atom(mod) and is_atom(fun) and is_list(args) do
    result = apply(mod, fun, args)
    send(pid, {:ok, result})
  end
end
