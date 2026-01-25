defmodule SafeNIFTest do
  use ExUnit.Case

  doctest SafeNIF

  test "Code.loaded?" do
    assert Code.loaded?(SafeNIF)
  end
end
