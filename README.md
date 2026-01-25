# SafeNIF

![Elixir CI](https://github.com/probably-not/safe-nif/actions/workflows/pipeline.yaml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hex version badge](https://img.shields.io/hexpm/v/safe_nif.svg)](https://hex.pm/packages/safe_nif)

<!-- README START -->

<!-- HEX PACKAGE DESCRIPTION START -->

Wrap your untrusted NIFs so that they can never crash your node.

<!-- HEX PACKAGE DESCRIPTION END -->


## Installation

[SafeNIF is available on Hex](https://hex.pm/packages/safe_nif).

To install, add it to you dependencies in your project's `mix.exs`.

```elixir
def deps do
  [
    {:safe_nif, ">= 0.0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/safe_nif>.

<!-- README END -->