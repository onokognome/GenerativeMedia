For example, MPD excerpt with a SegmentTemplate that is based on a SegmentTimeline is shown below.

1
2
3
4
5
6
7
8
9
10
11
12
<Representation mimeType="video/mp4"
                   frameRate="24"
                   bandwidth="1558322"
                   codecs="avc1.4d401f" width="1277" height="544">
  <SegmentTemplate media="http://cdn.bitmovin.net/bbb/video-1500/segment-$Time$.m4s"
                      initialization="http://cdn.bitmovin.net/bbb/video-1500/init.mp4"
                      timescale="24">
    <SegmentTimeline>
      <S t="0" d="48" r="5"/>
    </SegmentTimeline>
  </SegmentTemplate>
</Representation>
The resulting segment requests of the client would be as follows:

http://cdn.bitmovin.net/bbb/video-1500/init.mp4
http://cdn.bitmovin.net/bbb/video-1500/segment-0.m4s
http://cdn.bitmovin.net/bbb/video-1500/segment-48.m4s
http://cdn.bitmovin.net/bbb/video-1500/segment-96.m4s
…
