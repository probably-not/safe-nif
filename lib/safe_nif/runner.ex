defmodule SafeNIF.Runner do
  @moduledoc false
  use GenServer, restart: :temporary

  alias SafeNIF.WrappedCall

  defguardp is_runnable(runnable)
            when is_function(runnable, 0) or
                   (is_tuple(runnable) and
                      is_atom(elem(runnable, 0)) and
                      is_atom(elem(runnable, 1)) and
                      is_list(elem(runnable, 2)))

  def start_link({ref, runnable, caller} = init_arg)
      when is_reference(ref) and is_runnable(runnable) and is_pid(caller) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init({ref, runnable, caller}) do
    Process.flag(:trap_exit, true)
    {:ok, {ref, runnable, caller}, {:continue, :startup}}
  end

  @impl true
  def handle_continue(:startup, state) do
    node_name = :peer.random_name()
    :peer.start_link(%{name: node_name, wait_boot: {self(), :peer_ready}})
    {:noreply, state}
  end

  @impl true
  def handle_continue({:load_code, peer}, state) do
    load_code_on_peer(peer)
    {:noreply, state, {:continue, {:run, peer}}}
  end

  @impl true
  def handle_continue({:run, peer}, {ref, {_m, _f, _a} = runnable, caller}) do
    {m, f, a} = WrappedCall.call(self(), runnable)
    {_pid, monitor_ref} = Node.spawn_monitor(peer, m, f, a)
    {:noreply, {ref, monitor_ref, runnable, caller}}
  end

  @impl true
  def handle_continue({:run, peer}, {ref, runnable, caller}) do
    {_pid, monitor_ref} = Node.spawn_monitor(peer, WrappedCall.call(self(), runnable))
    {:noreply, {ref, monitor_ref, runnable, caller}}
  end

  @impl true
  def handle_info({:peer_ready, {:started, peer, _controller_pid}}, state) do
    {:noreply, state, {:continue, {:load_code, peer}}}
  end

  @impl true
  def handle_info({:ok, result}, {ref, monitor_ref, _runnable, caller} = state) do
    Process.demonitor(monitor_ref, [:flush])
    send(caller, {ref, result})
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, {ref, _, _runnable, caller} = state) do
    send(caller, {ref, {:error, reason}})
    {:stop, reason, state}
  end

  def load_code_on_peer(peer) do
    add_code_paths(peer)
    load_apps_and_transfer_configuration(peer, %{})
    ensure_apps_started(peer)
  end

  # TODO: This section can definitely be cleaned up.
  # Some examples:
  # - We're loading and starting everything - can we only load and start what is requested?
  # - We're ignoring errors in `:ensure_all_started`. Mostly this is to avoid dev issues... `:hex` for example. Is that bad?
  def rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end

  defp add_code_paths(node) do
    rpc(node, :code, :add_paths, [:code.get_path()])
  end

  defp load_apps_and_transfer_configuration(node, override_configs) do
    Enum.each(Application.started_applications(), fn {app_name, _, _} ->
      app_name
      |> Application.get_all_env()
      |> Enum.each(fn {key, primary_config} ->
        rpc(node, Application, :put_env, [app_name, key, primary_config, [persistent: true]])
      end)
    end)

    Enum.each(override_configs, fn {app_name, key, val} ->
      rpc(node, Application, :put_env, [app_name, key, val, [persistent: true]])
    end)
  end

  defp ensure_apps_started(node) do
    started_names = Enum.map(Application.started_applications(), fn {name, _, _} -> name end)

    Enum.reduce(started_names, MapSet.new(), fn app, started ->
      maybe_start_app(node, app, started)
    end)
  end

  defp maybe_start_app(node, app, started) do
    if Enum.member?(started, app) do
      started
    else
      case rpc(node, Application, :ensure_all_started, [app]) do
        {:ok, new_apps} -> MapSet.union(started, MapSet.new(new_apps))
        {:error, _reason} -> started
      end
    end
  end
end
