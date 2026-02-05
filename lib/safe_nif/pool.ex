defmodule SafeNIF.Pool do
  @moduledoc false

  @behaviour NimblePool

  alias SafeNIF.WrappedCall

  @enforce_keys [:node, :controller_pid]
  defstruct [:node, :controller_pid, :last_checkin]

  defmodule State do
    @moduledoc false
    @enforce_keys [:activity_info, :pool_max_idle_time, :peer_applications]
    defstruct [:activity_info, :pool_max_idle_time, :peer_applications]
  end

  def default_pool_name do
    __MODULE__.Default
  end

  @default_idle_timeout to_timeout(minute: 5)

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient
    }
  end

  def start_link(opts \\ []) do
    pool_size = Keyword.get(opts, :size, System.schedulers_online())
    idle_timeout = Keyword.get(opts, :idle_timeout, @default_idle_timeout)
    name = Keyword.fetch!(opts, :name)

    NimblePool.start_link(
      worker: {__MODULE__, opts},
      pool_size: pool_size,
      lazy: true,
      worker_idle_timeout: idle_timeout,
      name: name
    )
  end

  def run(pool, runnable, opts) do
    timeout = Keyword.get(opts, :timeout, to_timeout(second: 5))
    pool_timeout = Keyword.get(opts, :pool_timeout, to_timeout(second: 5))

    try do
      NimblePool.checkout!(
        pool,
        :checkout,
        fn _from, {peer, _idle_time} ->
          execute_on_peer(peer, runnable, timeout)
        end,
        pool_timeout
      )
    catch
      :exit, {:timeout, {NimblePool, :checkout, _}} ->
        {:error, :pool_timeout}

      :exit, {:noproc, {NimblePool, :checkout, _}} ->
        {:error, {:invalid_pool_name, pool}}

      :exit, reason ->
        {:error, reason}
    end
  end

  @impl NimblePool
  def init_pool(opts) do
    idle_timeout = Keyword.get(opts, :idle_timeout, @default_idle_timeout)
    peer_applications = Keyword.get(opts, :peer_applications, [:safe_nif])

    pool_state = %__MODULE__.State{
      activity_info: init_activity_info(),
      pool_max_idle_time: idle_timeout,
      peer_applications: peer_applications
    }

    {:ok, pool_state}
  end

  @impl NimblePool
  def init_worker(%__MODULE__.State{} = pool_state) do
    pool_pid = self()
    peer_applications = pool_state.peer_applications
    async = fn -> start_peer(pool_pid, peer_applications) end
    {:async, async, pool_state}
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, %__MODULE__{} = worker, %__MODULE__.State{} = pool_state) do
    idle_time = System.monotonic_time() - worker.last_checkin

    case Node.ping(worker.node) do
      :pong -> {:ok, {worker.node, idle_time}, worker, update_activity_info(:checkout, pool_state)}
      :pang -> {:remove, :nodedown, pool_state}
    end
  end

  @impl NimblePool
  def handle_checkin({:error, :nodedown}, _from, _worker, %__MODULE__.State{} = pool_state) do
    {:remove, :nodedown, update_activity_info(:checkin, pool_state)}
  end

  @impl NimblePool
  def handle_checkin({:error, :noproc}, _from, _worker, %__MODULE__.State{} = pool_state) do
    {:remove, :noproc, update_activity_info(:checkin, pool_state)}
  end

  @impl NimblePool
  def handle_checkin({:error, :noconnection}, _from, _worker, %__MODULE__.State{} = pool_state) do
    {:remove, :noconnection, update_activity_info(:checkin, pool_state)}
  end

  @impl NimblePool
  def handle_checkin(_checkin_state, _from, %__MODULE__{} = worker, %__MODULE__.State{} = pool_state) do
    worker = %{worker | last_checkin: System.monotonic_time()}
    {:ok, worker, update_activity_info(:checkin, pool_state)}
  end

  @impl NimblePool
  def handle_update(new_worker, _old_worker, %__MODULE__.State{} = pool_state) do
    {:ok, new_worker, pool_state}
  end

  @impl NimblePool
  def handle_info({:nodedown, node}, %__MODULE__{node: node}) do
    {:remove, :nodedown}
  end

  @impl NimblePool
  def handle_info({:link_controller, node}, %__MODULE__{node: node} = worker) do
    case Node.ping(worker.node) do
      :pong ->
        Process.link(worker.controller_pid)
        Node.monitor(worker.node, true)
        {:ok, worker}

      :pang ->
        {:remove, :nodedown}
    end
  end

  @impl NimblePool
  def handle_info(_message, worker) do
    {:ok, worker}
  end

  @impl NimblePool
  def handle_ping(%__MODULE__{} = worker, %__MODULE__.State{} = pool_state) do
    %__MODULE__.State{pool_max_idle_time: max_idle_time, activity_info: activity_info} = pool_state
    now = System.monotonic_time(:millisecond)
    diff_from_last_checkout = now - activity_info.last_checkout_ts

    is_idle? = diff_from_last_checkout > max_idle_time
    max_idle_time_configured? = is_number(max_idle_time)
    any_connection_in_use? = activity_info.in_use_count > 0

    cond do
      not max_idle_time_configured? -> {:ok, worker}
      any_connection_in_use? -> {:ok, worker}
      is_idle? -> {:stop, :idle_timeout}
      true -> {:ok, worker}
    end
  end

  @impl NimblePool
  def terminate_worker(_reason, %__MODULE__{node: peer}, pool_state) do
    try do
      :peer.stop(peer)
    catch
      :exit, _ -> :ok
    end

    {:ok, pool_state}
  end

  @impl NimblePool
  def handle_cancelled(:checked_out, _pool_state), do: :ok

  @impl NimblePool
  def handle_cancelled(:queued, _pool_state), do: :ok

  defp execute_on_peer(peer, runnable, timeout) do
    caller = self()
    {pid, monitor_ref} = spawn_on_peer(peer, runnable, caller)

    result =
      receive do
        {:ok, value} ->
          Process.demonitor(monitor_ref, [:flush])
          {:ok, value}

        {:DOWN, ^monitor_ref, :process, ^pid, :normal} ->
          receive do
            {:ok, value} -> {:ok, value}
          after
            0 -> {:error, :no_result}
          end

        {:DOWN, ^monitor_ref, :process, ^pid, reason} ->
          {:error, reason}
      after
        timeout ->
          Process.demonitor(monitor_ref, [:flush])
          Process.exit(pid, :kill)
          {:error, :timeout}
      end

    {result, result}
  end

  defp spawn_on_peer(peer, {_m, _f, _a} = runnable, caller) do
    {m, f, a} = WrappedCall.call(caller, runnable)
    Node.spawn_monitor(peer, m, f, a)
  end

  defp spawn_on_peer(peer, runnable, caller) when is_function(runnable, 0) do
    Node.spawn_monitor(peer, WrappedCall.call(caller, runnable))
  end

  defp start_peer(pool_pid, peer_applications) do
    node_name = :peer.random_name()
    caller = self()

    {:ok, controller_pid} =
      :peer.start_link(%{
        name: node_name,
        wait_boot: {caller, :peer_ready},
        args: peer_args()
      })

    peer =
      receive do
        {:peer_ready, {:started, peer, ^controller_pid}} -> peer
      end

    Process.unlink(controller_pid)

    add_code_paths(peer)
    transfer_configuration(peer)
    ensure_apps_started(peer, peer_applications)
    send(pool_pid, {:link_controller, peer})
    %__MODULE__{node: peer, controller_pid: controller_pid, last_checkin: System.monotonic_time()}
  end

  defp peer_args do
    args = [~c"-hidden"]
    args = maybe_add_cookie_args(args)
    in_release? = System.get_env("RELEASE_ROOT") != nil

    if in_release? do
      add_release_boot!(args)
    else
      args
    end
  end

  defp maybe_add_cookie_args(args) do
    case Node.get_cookie() do
      :nocookie -> args
      cookie -> [~c"-setcookie", Atom.to_charlist(cookie) | args]
    end
  end

  defp add_release_boot!(args) do
    release_root = System.fetch_env!("RELEASE_ROOT")
    release_vsn = System.fetch_env!("RELEASE_VSN")

    boot_path = Path.join([release_root, "releases", release_vsn, "start_clean"])
    boot_file = boot_path <> ".boot"

    if not File.exists?(boot_file) do
      raise RuntimeError, """
      The current running node was detected to be part of a mix release,
      with the `RELEASE_ROOT` environment variable set to
      #{release_root} and the `RELEASE_VSN` environment
      variable set to #{release_vsn}.

      We tried to load the `start_clean` bootfile from #{boot_file},
      but this file does not exist.
      """
    end

    release_lib = Path.join(release_root, "lib")

    [
      ~c"-boot",
      String.to_charlist(boot_path),
      ~c"-boot_var",
      ~c"RELEASE_LIB",
      String.to_charlist(release_lib)
      | args
    ]
  end

  defp rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end

  defp add_code_paths(node) do
    rpc(node, :code, :add_paths, [:code.get_path()])
  end

  defp transfer_configuration(node) do
    Enum.each(Application.loaded_applications(), fn {app_name, _, _} ->
      app_name
      |> Application.get_all_env()
      |> Enum.each(fn {key, primary_config} ->
        rpc(node, Application, :put_env, [app_name, key, primary_config, [persistent: true]])
      end)
    end)
  end

  defp ensure_apps_started(node, peer_applications) do
    Enum.reduce(peer_applications, MapSet.new(), fn app, started ->
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

  defp init_activity_info do
    %{in_use_count: 0, last_checkout_ts: System.monotonic_time(:millisecond)}
  end

  defp update_activity_info(:checkout, pool_state) do
    update_in(pool_state.activity_info, fn %{in_use_count: count} ->
      %{in_use_count: count + 1, last_checkout_ts: System.monotonic_time(:millisecond)}
    end)
  end

  defp update_activity_info(:checkin, pool_state) do
    update_in(pool_state.activity_info.in_use_count, &max(&1 - 1, 0))
  end
end
