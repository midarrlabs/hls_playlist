defmodule HlsPlaylist.Segments.Test do
  use ExUnit.Case

  test "it should generate" do
    assert HlsPlaylist.Segments.generate(32.21, 3.003) == [
      3.003,
      3.003,
      3.003,
      3.003,
      3.003,
      3.003,
      3.003,
      3.003,
      3.003,
      3.003,
      2.1799999999999997
    ]
  end
end
