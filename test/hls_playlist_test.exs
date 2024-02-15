defmodule HlsPlaylistTest do
  use ExUnit.Case

  @media_path "dev/sample__1080__libx264__ac3__30s__video.mp4"

  test "get duration" do
    assert HlsPlaylist.get_duration(@media_path) == 30.016
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
               2.582667
             ]
  end

  test "get playlist" do
    assert HlsPlaylist.get_segments(HlsPlaylist.get_keyframes(@media_path), HlsPlaylist.get_duration(@media_path))
           |> HlsPlaylist.get_playlist("http://some-url&some-query=param") ==
      """
      #EXTM3U
      #EXT-X-VERSION:3
      #EXT-X-ALLOW-CACHE:NO
      #EXT-X-TARGETDURATION:4
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
      #EXTINF:2.582667,
      http://some-url&some-query=param&segment=7
      #EXT-X-ENDLIST\
      """
  end

  test "get segment offset" do
    playlist =
      """
      #EXTM3U
      #EXT-X-VERSION:3
      #EXT-X-ALLOW-CACHE:NO
      #EXT-X-TARGETDURATION:4
      #EXT-X-MEDIA-SEQUENCE:0
      #EXT-X-PLAYLIST-TYPE:VOD
      #EXTINF:4.166667,
      0
      #EXTINF:4.166666,
      1
      #EXTINF:4.166667,
      2
      #EXTINF:3.766667,
      3
      #EXTINF:3.866666,
      4
      #EXTINF:4.166667,
      5
      #EXTINF:3.133333,
      6
      #EXTINF:2.582667,
      7
      #EXT-X-ENDLIST\
      """

    assert {3.766667, 12.5} = HlsPlaylist.get_segment_offset(String.split(playlist), String.to_integer("3"))
  end
end
