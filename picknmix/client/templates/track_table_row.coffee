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
      beats = beatManager.getBeats()
      Tracks.update track._id,
        $set:
          bpm: bpm
          beats: beats
          numBeats: beats.length
      Tracks.set track._id, beatManager.getAudioSample().buffer

