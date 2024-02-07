defmodule HlsPlaylist do
  @moduledoc """
  Documentation for `HlsPlaylist`.
  """

  def get_keyframes(path) do
    Exile.stream!([
      "ffprobe",
      "-v","error",
      "-skip_frame", "nokey",
      "-show_entries", "format=duration",
      "-show_entries", "stream=duration",
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
    |> Enum.map(fn x -> String.trim_leading(Enum.at(x, 0), "packet,")  end)
  end

  def get_segments(keyframes, duration, segment_length) do
    {last_segment, segment_lengths, _} =
      Enum.reduce(keyframes, {0, [], segment_length}, fn kf, {last_segment, segment_lengths, current_desired_time} ->
        desired_segment_length = current_desired_time - last_segment

        {kf_next, kf_next_distance} =
          case Enum.find_index(keyframes, &(&1 > kf)) do
            nil -> {nil, nil}
            index ->
              {Enum.at(keyframes, index), Enum.at(keyframes, index) - last_segment}
          end

        kf_distance = kf - last_segment
        kf_distance_from_desire = abs(desired_segment_length - kf_distance)
        kf_next_distance_from_desire =
          case {kf_next, kf_next_distance} do
            {nil, _} -> nil
            {_next_kf, next_distance} -> abs(desired_segment_length - next_distance)
          end

        cond do
          kf_next_distance_from_desire &&
            kf_next_distance_from_desire <= 1 &&
            kf_next_distance_from_desire <= kf_distance_from_desire ->
            {last_segment, segment_lengths, current_desired_time}

          kf_distance >= desired_segment_length ->
            new_segment_lengths = [kf_distance |> Float.round(3) | segment_lengths]
            new_last_segment = kf
            new_desired_time = current_desired_time + segment_length
            {new_last_segment, new_segment_lengths, new_desired_time}

          true ->
            {last_segment, segment_lengths, current_desired_time}
        end
      end)

    remaining_segment_length = duration - last_segment
    Enum.reverse([remaining_segment_length |> Float.round(3) | segment_lengths])
  end
end
