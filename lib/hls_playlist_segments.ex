defmodule HlsPlaylist.Segments do

  def generate(duration, segment_length \\ 3) when duration > 0 and segment_length > 0 do
    spread_duration(duration, segment_length, [])
  end

  defp spread_duration(duration, _segment_length, acc) when duration <= 0 do
    Enum.reverse(acc)
  end

  defp spread_duration(duration, segment_length, acc) do
    next_duration = min(duration, segment_length)

    spread_duration(duration - next_duration, segment_length, [next_duration | acc])
  end
end
