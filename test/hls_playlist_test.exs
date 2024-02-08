defmodule HlsPlaylistTest do
  use ExUnit.Case
  doctest HlsPlaylist

  test "get_duration" do
    assert HlsPlaylist.get_duration("dev/sample__1080__libx264__ac3__30s__video.mp4") == 30.0
  end

  test "get_keyframes" do
    assert HlsPlaylist.get_keyframes("dev/sample__1080__libx264__ac3__30s__video.mp4") == [
             "0.000000,-0.033333,K__",
             "4.166667,4.133333,K__",
             "8.333333,8.300000,K__",
             "12.500000,12.466667,K__",
             "16.266667,16.233333,K__",
             "20.133333,20.100000,K__",
             "24.300000,24.266667,K__",
             "27.433333,27.400000,K__"
           ]
  end

  test "get_segments" do
    keyframes = [
      0.000000,
      4.166667,
      8.333333,
      12.500000,
      16.266667,
      20.133333,
      24.300000,
      27.433333
    ]

    duration = 30.0
    segment_length = 3

    assert HlsPlaylist.get_segments(keyframes, duration, segment_length) ==
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
    segment_lengths =
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

    segment_name = "segment"

    # a little off from ffmpeg-generated.m3u8
    #
    # #EXTINF:4.166666, should be #EXTINF:4.166667
    # segment1.ts
    #
    # #EXTINF:3.866666, should be #EXTINF:3.866667
    # segment4.ts
    expected_playlist =
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

    assert HlsPlaylist.get_playlist(segment_lengths, segment_name) == expected_playlist
  end
end
