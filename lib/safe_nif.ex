defmodule SafeNIF do
  @moduledoc """
  #{"./README.md" |> Path.expand() |> File.read!() |> String.split("<!-- README START -->") |> Enum.at(1) |> String.split("<!-- README END -->") |> List.first() |> String.trim()}
  """

  alias SafeNIF.Runner

  @typedoc """
  Anything that is runnable. This may be a function, or an MFA that can be used in `apply/3`.
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

  defp do_wrap(runnable, timeout) do
    ref = make_ref()
    caller = self()

    case DynamicSupervisor.start_child(SafeNIF.DynamicSupervisor, Runner.child_spec({ref, runnable, caller})) do
      {:ok, pid} when is_pid(pid) -> wait(pid, ref, timeout)
      {:error, {:already_started, pid}} when is_pid(pid) -> wait(pid, ref, timeout)
      error -> error
    end
  end

  defp wait(pid, ref, timeout) do
    monitor_ref = Process.monitor(pid)

    receive do
      {^ref, result} ->
        Process.demonitor(monitor_ref, [:flush])
        {:ok, result}

      {:DOWN, ^ref, :process, ^pid, reason} ->
        {:error, reason}
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        Process.exit(pid, :kill)
        {:error, :timeout}
    end
  end
end
