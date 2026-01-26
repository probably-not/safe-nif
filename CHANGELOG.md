# Changelog

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
