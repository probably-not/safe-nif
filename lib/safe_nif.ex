defmodule SafeNIF do
  @moduledoc """
  #{"./README.md" |> Path.expand() |> File.read!() |> String.split("<!-- README START -->") |> Enum.at(1) |> String.split("<!-- README END -->") |> List.first() |> String.trim()}
  """

  @typedoc """
  Anything that is runnable. This may be a function, or an MFA tuple.
  """
  @type runnable() :: (-> term()) | {module(), atom(), list()}

  @typedoc """
  Options to pass into `wrap/1` or `wrap/4`.

  ## Options

    * `:timeout` - A timeout to be passed into the function, defaulting to 5 seconds.
      Should the function take longer than the given timeout the underlying process
      will be force killed and `{:error, :timeout}` will be returned.
    * `:pool` - A pool configured with custom values for size and idle node time.
      Defaults to the default pool started up with the application.
    * `:pool_timeout` - A timeout for how long it should take to checkout a node from the pool, defaulting to 5 seconds.
      Should the pool checkout take longer than the given timeout `{:error, :timeout}` will be returned.
  """
  @type wrap_opt() :: {:timeout, timeout()} | {:pool_timeout, timeout()} | {:pool, atom()}

  @typedoc """
  Options to pass into a new pool when adding it to the supervision tree.

  ## Options

    * `:name` (**required**) - An `t:atom/0` name to give to the pool.
    * `:size` - How many workers to put in the pool. Defaults to `System.schedulers_online/0`.
    * `:idle_timeout` - How long to allow the pool and nodes to be idle until we start scaling them down.
    * `:peer_applications` - A list of applications to start on the peer node, defaulting to just `:safe_nif`.
      If you need a custom list of applications that must start on the peer node, make sure to pass their names into the pool.
  """
  @type pool_start_opt() ::
          {:name, atom()} | {:size, pos_integer()} | {:idle_timeout, timeout()} | {:peer_applications, [atom()]}

  @doc false
  defdelegate child_spec(args), to: SafeNIF.Pool

  @doc """
  Wrap a call in a way that will ensure that it cannot affect the current BEAM node.

  This will raise a separate BEAM node via the Erlang [`:peer`](https://www.erlang.org/doc/apps/stdlib/peer.html) module, and run the runnable on that node.
  The current node remains isolated, and results are communicated between the two via Erlang Distribution.

  Since this uses Erlang Distribution under the hood, it requires that the current node be alive. If the current
  node is not alive, an error of `{:error, :not_alive}` will be returned.

  The result of the function is emitted wrapped in an `:ok` tuple. This mirrors `Task.async_stream/5`, which always emits
  an `:ok` tuple wrapping the result of running the function value regardless of if the return value is an error.

  Should the function cause a crash, the reason will be wrapped in an error tuple and returned as `{:error, reason}`.

  ## Options

    * `:timeout` - A timeout to be passed into the function, defaulting to 5 seconds.
      Should the function take longer than the given timeout the underlying process
      will be force killed and `{:error, :timeout}` will be returned.
    * `:pool` - A pool configured with custom values for size and idle node time.
      Defaults to the default pool started up with the application.
    * `:pool_timeout` - A timeout for how long it should take to checkout a node from the pool, defaulting to 5 seconds.
      Should the pool checkout take longer than the given timeout `{:error, :timeout}` will be returned.


  ## Node Pools

  In order to avoid startup costs of initializing a full BEAM node and loading all of the necessary code onto it on each call,
  `SafeNIF` implements a `NimblePool` based resource pool for [`:peer`](https://www.erlang.org/doc/apps/stdlib/peer.html) nodes,
  allowing nodes to be reused across calls. By default, a pool is created with default values for idle time (5 minutes) and sizing
  (based on `System.schedulers_online/0`). However, based on your demand, you may need to tune these values.
  All benchmarks in SafeNIF were conducted with these defaults, but you can create your own pools and use them by passing in the `:pool`
  option to `wrap/1` and `wrap/4`.

  Creating a pool is as easy as adding `{SafeNIF, opts}` (where opts is a list of `t:pool_start_opt/0`) into your supervision tree, and customizing these options for your use case.

  ### Node Pool Options
    * `:name` (**required**) - An `t:atom/0` name to give to the pool.
    * `:size` - How many workers to put in the pool. Defaults to `System.schedulers_online/0`.
    * `:idle_timeout` - How long to allow the pool and nodes to be idle until we start scaling them down.
    * `:peer_applications` - A list of applications to start on the peer node, defaulting to just `:safe_nif`.
      If you need a custom list of applications that must start on the peer node, make sure to pass their names into the pool.

  """
  @spec wrap(runnable(), [wrap_opt()]) :: {:ok, term()} | {:error, term()}
  def wrap(runnable, opts \\ []) do
    if Node.alive?() do
      do_wrap(runnable, opts)
    else
      {:error, :not_alive}
    end
  end

  @doc """
  Wrap a call in a way that will ensure that it cannot affect the current BEAM node.

  Like `wrap/1` but accepts an MFA that will be used with `apply/3`.

  See `wrap/1` for more details.
  """
  @spec wrap(module(), atom(), list(), [wrap_opt()]) :: {:ok, term()} | {:error, term()}
  def wrap(mod, fun, args, opts \\ []) when is_atom(mod) and is_atom(fun) and is_list(args) do
    if Node.alive?() do
      do_wrap({mod, fun, args}, opts)
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

  defp do_wrap(runnable, timeout) when is_runnable(runnable) and is_integer(timeout) do
    # For now, we're going to manually catch this, so that people won't be affected.
    # But, it is deprecated... so it should be removed eventually.
    do_wrap(runnable, timeout: timeout)
  end

  defp do_wrap(runnable, opts) when is_runnable(runnable) do
    opts = Keyword.validate!(opts, [:timeout, :pool_timeout, pool: SafeNIF.Pool.default_pool_name()])
    {pool, opts} = Keyword.pop!(opts, :pool)
    SafeNIF.Pool.run(pool, runnable, opts)
  end
end
