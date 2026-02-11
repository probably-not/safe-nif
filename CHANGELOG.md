# Changelog

## [0.4.0] - 2026-02-11

`SafeNIF` pools are now correctly cleaned up, instead of being terminated. My original pool implementation was essentially a copy of [Finch's HTTP1.Pool module](https://github.com/sneako/finch/blob/main/lib/finch/http1/pool.ex) just replaced with functionality that initialized peer nodes and handled everything lazily. However, I made a mistake in copying the `handle_ping` callback. Finch's `handle_ping` will shut down the entire pool if the pool is idle. For Finch, this is fine, since the rest of Finch will ensure that pools are started for hosts and the like, but for `SafeNIF` this is very bad - because pools will die off when they shouldn't.

This release ensures that the restart option for the pool is set to `:permanent`, and removes all of the copied Finch code with activity handling, timeout handling, and full pool stopping, and replaces it with simple ping removal - when a worker is pinged as idle, we remove it from the pool.

## [0.3.0] - 2026-02-05

`SafeNIF` now detects whether or not you are in a release, and will automatically use your current release's `start_clean.boot` bootfile in order to start up the `:peer` node. This ensures that `SafeNIF` can work properly with Elixir's mix release system, something that I unfortunately fully didn't test out before pushing this out to production.

## [0.2.1] - 2026-01-27

### Added

- `:peer_applications` - For custom pools, you can decide which applications will be started on the peer nodes. In the default pool this defaults to only `:safe_nif`, and if not passed in to custom pools it will default to `:safe_nif` as well

## [0.2.0] - 2026-01-27

Pooling `:peer` nodes has been implemented!
You now no longer incur the startup costs of nodes on every call, instead, you only incur them on the first call.

### Breaking Changes
- `SafeNIF.wrap/1` and `SafeNIF.wrap/4` now receive a `t:Keyword.t/0` as their last parameter instead of a timeout directly. This is in order to allow us to pass details like the pool name (if you have a custom pool), and details related to timeouts of the pool.

### Notes

Pooled `:peer` nodes are implemented with the following details:
- They are lazily created, so they will not start up until the first call.
- They are killed if they are idle, to ensure that when they are not in use they will scale in.

## [0.1.1] - 2026-01-27

Minor fixes to the documentation.

This release doesn't change anything with regards to functionality, but I realized that I left moduledocs on the bench and test modules which were then placed into HexDocs.
This release is simply to make those all false, and fix up the HexDocs functionality.

## [0.1.0] - 2026-01-26

Initial release.

### Added

- `SafeNIF.wrap/2` and `SafeNIF.wrap/4` - Execute functions on isolated peer nodes with crash protection
- Automatic code path and application configuration transfer to peer nodes
- Hidden node support - peer nodes don't appear in `Node.list/0` or trigger `:net_kernel` monitors
- Configurable timeouts via `to_timeout/1`
- Telemetry events for supervisor metrics (`:safe_nif, :supervisor`)

### Notes

This is an experimental release. The API may change in future versions.

Current limitations:
- Each call starts a new peer node, incurring node startup overhead
- Anonymous functions only work if their defining module is loaded on the peer
- Requires the calling node to be running in distributed mode
