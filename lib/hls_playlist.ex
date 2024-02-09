defmodule HlsPlaylist do
  @moduledoc """
  Documentation for `HlsPlaylist`.
  """

  def get_duration(path) do
    Exile.stream!([
      "ffprobe",
      "-v","error",
      "-show_entries", "stream=duration",
      "-select_streams", "v",
      "-of", "csv",
      "-i", path,
    ])
    |> Enum.at(0)
    |> String.trim()
    |> String.trim_leading("stream,")
    |> String.to_float()
  end

  def get_keyframes(path) do
    Exile.stream!([
      "ffprobe",
      "-v","error",
      "-skip_frame", "nokey",
      "-show_entries", "packet=pts_time,dts_time,flags",
      "-select_streams", "v",
      "-of", "csv",
      "-i", path,
    ])
    |> Enum.map(fn x ->
      String.trim(x)
      |> String.split("\n")
      |> Enum.filter(fn x -> String.contains?(x, "K__") end)
    end)
    |> Enum.reject(fn x -> Enum.empty?(x) end)
    |> Enum.map(fn x ->
      String.trim_leading(Enum.at(x, 0), "packet,")
      |> String.trim_trailing(",K__")
      |> String.split(",")
      |> Kernel.hd()
      |> String.to_float
    end)
  end

  def get_segments(keyframes, duration, segment_length) do
    {last_segment, segment_lengths, _} =
      Enum.reduce(keyframes, {0, [], segment_length}, fn kf,
                                                         {last_segment, segment_lengths,
                                                          current_desired_time} ->
        desired_segment_length = current_desired_time - last_segment

        {kf_next, kf_next_distance} =
          case Enum.find_index(keyframes, &(&1 > kf)) do
            nil ->
              {nil, nil}

            index ->
              {Enum.at(keyframes, index), Enum.at(keyframes, index) - last_segment}
          end

        kf_distance = kf - last_segment
        kf_distance_from_desire = Kernel.abs(desired_segment_length - kf_distance)

        kf_next_distance_from_desire =
          case {kf_next, kf_next_distance} do
            {nil, _} -> nil
            {_next_kf, next_distance} -> Kernel.abs(desired_segment_length - next_distance)
          end

        cond do
          kf_next_distance_from_desire &&
            kf_next_distance_from_desire <= 1 &&
              kf_next_distance_from_desire <= kf_distance_from_desire ->
            {last_segment, segment_lengths, current_desired_time}

          kf_distance >= desired_segment_length ->
            new_segment_lengths = [kf_distance |> Float.round(6) | segment_lengths]
            new_last_segment = kf
            new_desired_time = current_desired_time + segment_length
            {new_last_segment, new_segment_lengths, new_desired_time}

          true ->
            {last_segment, segment_lengths, current_desired_time}
        end
      end)

    remaining_segment_length = duration - last_segment
    Enum.reverse([remaining_segment_length |> Float.round(6) | segment_lengths])
  end

  def get_playlist(segment_lengths, segment_name) do
    {segments, largest_segment} =
      Enum.reduce(segment_lengths, {[], 0.0}, fn segl, {acc, current_largest} ->
        largest_segment = max(segl, current_largest)

        extinf_segment =
          "#EXTINF:#{String.Chars.to_string(segl)},\n#{segment_name}#{length(acc)}.ts"

        {[extinf_segment | acc], largest_segment}
      end)

    """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-ALLOW-CACHE:NO
    #EXT-X-TARGETDURATION:#{Kernel.trunc(Float.floor(largest_segment))}
    #EXT-X-MEDIA-SEQUENCE:0
    #EXT-X-PLAYLIST-TYPE:VOD
    #{Enum.join(Enum.reverse(segments), "\n")}
    #EXT-X-ENDLIST\
    """
  end
end
