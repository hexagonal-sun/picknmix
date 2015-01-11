Template.TrackTableRow.events
  'click button': (event, template) ->
    event.preventDefault()
    {track, audioContext} = template.data
    beatManager = new BeatDetector.BeatManager(audioContext)
    beatManager.fromUrl(track.previewUrl)
    template.autorun (computation) -> 
      unless (bpm = beatManager.getCurrentBpm())?
        return
      computation.stop()
      Tracks.update track._id,
        $set:
          bpm: bpm
          beats: beatManager.getBeats()
      Tracks.set track._id, beatManager.getAudioSample().buffer

