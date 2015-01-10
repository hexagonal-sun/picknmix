Template.TrackTableRow.events
  'click button': (event, template) ->
    event.preventDefault()
    {data:track} = template
    beatManager = new BeatDetector.BeatManager
    beatManager.fromUrl(track.previewUrl)
    template.autorun (computation) -> 
      bpm = beatManager.getCurrentBpm()
      return if bpm == 0
      computation.stop()
      Tracks.update track._id,
        $set:
          bpm: bpm
