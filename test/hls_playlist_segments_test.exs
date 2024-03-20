defmodule HlsPlaylist.Segments.Test do
  use ExUnit.Case

  test "it should generate" do
    assert HlsPlaylist.Segments.generate(32.21, 3) == [
      3.0,
      3.0,
      3.0,
      3.0,
      3.0,
      3.0,
      3.0,
      3.0,
      3.0,
      3.0,
      2.21
    ]
  end
end
