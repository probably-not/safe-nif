defmodule SafeNIF do
  @moduledoc """
  #{"./README.md" |> Path.expand() |> File.read!() |> String.split("<!-- README START -->") |> Enum.at(1) |> String.split("<!-- README END -->") |> List.first() |> String.trim()}
  """

  @typedoc """
  Anything that is runnable. This may be a function, or an MFA tuple.
  """
  @type runnable() :: (-> term()) | {module(), atom(), list()}

  @doc """
  Wrap a call in a way that will ensure that it cannot affect the current BEAM node.

  This will raise a separate BEAM node via the Erlang [`:peer`](https://www.erlang.org/doc/apps/stdlib/peer.html) module, and run the runnable on that node.
  The current node remains isolated, and results are communicated between the two via Erlang Distribution.

  Since this uses Erlang Distribution under the hood, it requires that the current node be alive. If the current
  node is not alive, an error of `{:error, :not_alive}` will be returned.

  The result of the function is emitted wrapped in an `:ok` tuple. This mirrors `Task.async_stream/5`, which always emits
  an `:ok` tuple wrapping the result of running the function value regardless of if the return value is an error.

  Should the function cause a crash, the reason will be wrapped in an error tuple and returned as `{:error, reason}`.

  A timeout can be passed into the function, defaulting to 5 seconds. Should the function take longer than the given timeout
  the underlying process will be force killed and `{:error, :timeout}` will be returned.
  """
  @spec wrap(runnable(), timeout()) :: {:ok, term()} | {:error, term()}
  def wrap(runnable, timeout \\ to_timeout(second: 5)) do
    if Node.alive?() do
      do_wrap(runnable, timeout)
    else
      {:error, :not_alive}
    end
  end

  @doc """
  Wrap a call in a way that will ensure that it cannot affect the current BEAM node.

  Like `wrap/1` but accepts an MFA that will be used with `apply/3`.

  See `wrap/1` for more details.
  """
  @spec wrap(module(), atom(), list(), timeout()) :: {:ok, term()} | {:error, term()}
  def wrap(mod, fun, args, timeout \\ to_timeout(second: 5)) when is_atom(mod) and is_atom(fun) and is_list(args) do
    if Node.alive?() do
      do_wrap({mod, fun, args}, timeout)
    else
      {:error, :not_alive}
    end
  end

  defguardp is_runnable(runnable)
            when is_function(runnable, 0) or
                   (is_tuple(runnable) and
                      is_atom(elem(runnable, 0)) and
                      is_atom(elem(runnable, 1)) and
                      is_list(elem(runnable, 2)))

  defp do_wrap(runnable, timeout) when is_runnable(runnable) do
    SafeNIF.Pool.run(runnable, timeout: timeout)
  end
end
