defmodule SafeNIFTest.Helpers do
  @moduledoc false

  def return_value(value), do: value

  def return_42, do: 42

  def return_complex_data do
    %{
      list: [1, 2, 3],
      tuple: {:ok, "value"},
      nested: %{deep: [a: 1, b: 2]}
    }
  end

  def return_large_binary(size) do
    :crypto.strong_rand_bytes(size)
  end

  def return_self_node, do: node()

  def return_self_pid, do: self()

  def return_make_ref, do: make_ref()

  def sleep_forever, do: Process.sleep(:infinity)

  def sleep_ms(ms), do: Process.sleep(ms)

  def halt_node(code), do: :erlang.halt(code)

  def raise_error(message), do: raise(message)

  def throw_value(value), do: throw(value)

  def exit_with(reason), do: exit(reason)

  def enum_sum(list), do: Enum.sum(list)

  def crypto_hash(algorithm, data), do: :crypto.hash(algorithm, data)

  def get_app_env(app, key), do: Application.get_env(app, key)

  def spawn_processes(count) do
    pids = for _ <- 1..count, do: spawn(fn -> Process.sleep(100) end)
    length(pids)
  end

  def multiply(a, b), do: a * b
end
