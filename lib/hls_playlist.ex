defmodule HlsPlaylist do

  def get_duration(path) do
    Exile.stream!([
      "ffprobe",
      "-v","error",
      "-select_streams", "v:0",
      "-show_entries", "stream=duration",
      "-of", "default=noprint_wrappers=1:nokey=1",
      path
    ])
    |> Enum.at(0)
    |> String.trim()
    |> String.to_float()
  end

  def get_keyframes(path) do
    Exile.stream!([
      "awk", "-F,", "/K_/ {print $1}"
    ], input: fn sink ->
      Exile.stream!([
        "ffprobe",
        "-v", "error",
        "-select_streams", "v:0",
        "-skip_frame", "nokey",
        "-show_entries", "packet=pts_time,flags",
        "-of", "csv=nk=1:p=0",
        path
      ])
      |> Stream.into(sink)
      |> Stream.run()
    end)
    |> Stream.flat_map(fn x ->
      String.trim(x)
      |> String.split("\n")
    end)
    |> Enum.map(fn x -> String.to_float x end)
  end

  def get_segments(keyframes, duration, segment_length \\ 3) do
    {last_segment, segment_lengths, _} =
      Enum.reduce(keyframes, {0, [], segment_length}, fn keyframe, {last_segment, segment_lengths, current_desired_time} ->
        desired_segment_length = current_desired_time - last_segment

        keyframe_distance = keyframe - last_segment

        cond do
          keyframe_distance >= desired_segment_length ->
            {keyframe, [keyframe_distance |> Float.round(6) | segment_lengths], current_desired_time + segment_length}

          true ->
            {last_segment, segment_lengths, current_desired_time}
        end
      end)

    Enum.reverse([duration - last_segment |> Float.round(6) | segment_lengths])
  end

  def get_playlist(segments_all, segment_name \\ "") do
    {segments, largest_segment} =
      Enum.reduce(segments_all, {[], 0.0}, fn segment_length, {acc, current_largest} ->
        largest_segment = max(segment_length, current_largest)

        extinf_segment =
          "#EXTINF:#{String.Chars.to_string(segment_length)},\n#{segment_name}&segment=#{length(acc)}"

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

  def get_segment_offset(playlist, target_segment, current_duration \\ 0.0, total_duration \\ 0.0, index \\ 0) do
    case playlist do
      [line | rest] ->
        case String.match?(line, ~r{^#EXTINF:(\d+\.\d+),}) do
          true ->
            [_, segment_duration] = Regex.run(~r{^#EXTINF:(\d+\.\d+),}, line, capture: :all)
            segment_duration = String.to_float(segment_duration)

            if index == target_segment do
              {segment_duration, total_duration + current_duration}  # Return both the duration of the target segment and total offset duration
            else
              get_segment_offset(rest, target_segment, current_duration + segment_duration, total_duration, index + 1)
            end

          false ->
            get_segment_offset(rest, target_segment, current_duration, total_duration, index)
        end
    end
  end
end
