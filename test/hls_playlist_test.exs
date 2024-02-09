defmodule HlsPlaylistTest do
  use ExUnit.Case
  doctest HlsPlaylist

  @media_path "dev/sample__1080__libx264__ac3__30s__video.mp4"

  test "get_duration" do
    assert HlsPlaylist.get_duration(@media_path) == 30.0
  end

  test "get_keyframes" do
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

  test "get_segments" do
    assert HlsPlaylist.get_segments(HlsPlaylist.get_keyframes(@media_path), HlsPlaylist.get_duration(@media_path), 3) ==
             [
               4.166667,
               4.166666,
               4.166667,
               3.766667,
               3.866666,
               4.166667,
               3.133333,
               2.566667
             ]
  end

  test "get_playlist" do
    assert HlsPlaylist.get_playlist(HlsPlaylist.get_segments(HlsPlaylist.get_keyframes(@media_path), HlsPlaylist.get_duration(@media_path), 3), "segment") ==

     # a little off from generated-ffmpeg.m3u8
     #
     # #EXTINF:4.166666, should be #EXTINF:4.166667
     # segment1.ts
     #
     # #EXTINF:3.866666, should be #EXTINF:3.866667
     # segment4.ts
      """
      #EXTM3U
      #EXT-X-VERSION:3
      #EXT-X-ALLOW-CACHE:NO
      #EXT-X-TARGETDURATION:4
      #EXT-X-MEDIA-SEQUENCE:0
      #EXT-X-PLAYLIST-TYPE:VOD
      #EXTINF:4.166667,
      segment0.ts
      #EXTINF:4.166666,
      segment1.ts
      #EXTINF:4.166667,
      segment2.ts
      #EXTINF:3.766667,
      segment3.ts
      #EXTINF:3.866666,
      segment4.ts
      #EXTINF:4.166667,
      segment5.ts
      #EXTINF:3.133333,
      segment6.ts
      #EXTINF:2.566667,
      segment7.ts
      #EXT-X-ENDLIST\
      """
  end
end
