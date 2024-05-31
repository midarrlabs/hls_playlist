defmodule HlsPlaylistTest do
  use ExUnit.Case

  @media_path "dev/sample__1080__libx264__ac3__30s__video.mp4"

  test "get duration" do
    assert HlsPlaylist.get_duration(@media_path) == 30.01
  end

  test "get keyframes" do
    assert HlsPlaylist.get_keyframes(@media_path) == [
             0.0,
             4.166667,
             8.333333,
             12.5,
             16.266667,
             20.133333,
             24.3,
             27.433333
           ]
  end

  test "get segments" do
    assert HlsPlaylist.get_segments(HlsPlaylist.get_keyframes(@media_path), HlsPlaylist.get_duration(@media_path)) ==
             [
               4.166667,
               4.166666,
               4.166667,
               3.766667,
               3.866666,
               4.166667,
               3.133333,
               2.576667
             ]
  end

  test "get playlist" do
    assert HlsPlaylist.get_segments(HlsPlaylist.get_keyframes(@media_path), HlsPlaylist.get_duration(@media_path))
           |> HlsPlaylist.get_playlist("http://some-url&some-query=param") ==
      """
      #EXTM3U
      #EXT-X-VERSION:3
      #EXT-X-ALLOW-CACHE:NO
      #EXT-X-TARGETDURATION:5
      #EXT-X-MEDIA-SEQUENCE:0
      #EXT-X-PLAYLIST-TYPE:VOD
      #EXTINF:4.166667,
      http://some-url&some-query=param&segment=0
      #EXTINF:4.166666,
      http://some-url&some-query=param&segment=1
      #EXTINF:4.166667,
      http://some-url&some-query=param&segment=2
      #EXTINF:3.766667,
      http://some-url&some-query=param&segment=3
      #EXTINF:3.866666,
      http://some-url&some-query=param&segment=4
      #EXTINF:4.166667,
      http://some-url&some-query=param&segment=5
      #EXTINF:3.133333,
      http://some-url&some-query=param&segment=6
      #EXTINF:2.576667,
      http://some-url&some-query=param&segment=7
      #EXT-X-ENDLIST\
      """
  end

  test "get segment offset with overlap" do
    segments = [
      4.166667,
      4.166666,
      4.166667,
      3.766667,
      3.866666,
      4.166667,
      3.133333,
      2.576667
    ]
    overlap = 1.0

    assert {"00:00:02.767", "00:00:09.500"} = HlsPlaylist.get_segment_offset(segments, 3, overlap)
  end

  test "get segment offset with different overlap" do
    segments = [
      4.166667,
      4.166666,
      4.166667,
      3.766667,
      3.866666,
      4.166667,
      3.133333,
      2.576667
    ]
    overlap = 0.5

    assert {"00:00:03.267", "00:00:11.000"} = HlsPlaylist.get_segment_offset(segments, 3, overlap)
  end

  test "get segment offset for first segment" do
    segments = [
      4.166667,
      4.166666,
      4.166667,
      3.766667,
      3.866666,
      4.166667,
      3.133333,
      2.576667
    ]
    overlap = 1.0

    assert {"00:00:03.167", "00:00:00.000"} = HlsPlaylist.get_segment_offset(segments, 0, overlap)
  end

  test "get segment offset for last segment" do
    segments = [
      4.166667,
      4.166666,
      4.166667,
      3.766667,
      3.866666,
      4.166667,
      3.133333,
      2.576667
    ]
    overlap = 1.0

    assert {"00:00:01.577", "00:00:20.433"} = HlsPlaylist.get_segment_offset(segments, 7, overlap)
  end
end
