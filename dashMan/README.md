Time Based SegmentTemplate
The SegmentTemplate element could also contain a $Time$ identifier, which will be substituted with the value of the t attribute from the SegmentTimeline. The SegmentTimeline element provides an alternative to the duration attribute with additional features such as:

specifying arbitrary segment durations
specifying exact segment durations
specifying discontinuities in the media timeline
The SegmentTimeline also uses run-length compression, which is especially efficient when having a sequence of segments with the same duration. When SegmentTimline is used with SegmentTemplate then the following conditions must apply:

at least one sidx box shall be present
all values of the SegmentTimeline shall describe accurate
timing, equal to the information in the sidx box
For example, MPD excerpt with a SegmentTemplate that is based on a SegmentTimeline is shown below.
```
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
```
