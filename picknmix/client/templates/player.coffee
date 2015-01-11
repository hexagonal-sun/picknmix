Template.Player.created = ->
  @_player = new Player @data.audioContext
  @_player.start()

Template.Player.destroyed = ->
  @_player.stop()

Template.Player.helpers
  currentTrack: ->
    Template.instance()._player.getCurrentTrack()

class Player
  constructor: (@_ctx) ->
    @_nextStartTime = null
    @_currentTrack = new ReactiveVar()
    @_targetBpm = 120
    @_numBeats = 12
    @_mixBeats = 2
    @_offsetBeats = 4

  _findNextTrack: =>
    query =
      bpm:
        $exists: true
    if (currentTrack = @_currentTrack.get())?
      query._id =
        $ne: currentTrack._id

    cursor = Tracks.find query

    return if cursor.count() == 0
    tracks = (t for t in cursor.fetch() when t.beats.length >= @_numBeats)
    return if tracks.length == 0
    tracks[Math.floor(tracks.length * Math.random())]

  start: =>
    @_comp = Tracker.autorun (computation) =>
      if @_findNextTrack()?
        computation.stop()
        @_main()
 
  stop: =>
    @_comp.stop()

  getCurrentTrack: =>
    @_currentTrack.get()

  _main: =>
    @_nextStartTime ?= @_ctx.currentTime
    track = @_findNextTrack()
    @_currentTrack.set(track)
    source = @_ctx.createBufferSource()
    source.buffer = Tracks.get track._id
    gain = @_ctx.createGain()
    source.connect gain
    gain.connect @_ctx.destination
    source.onended = @_onEnded
    gain.gain.setValueAtTime(0, @_ctx.currentTime)
    introTime = 60/@_targetBpm * @_mixBeats
    console.log(introTime)
    gain.gain.linearRampToValueAtTime(1, @_ctx.currentTime + introTime)
    source.playbackRate.value = @_targetBpm / track.bpm
    startBeat = track.beats[@_offsetBeats]
    endBeat = track.beats[@_offsetBeats + @_numBeats]
    duration = endBeat - startBeat
    source.start @_nextStartTime, startBeat, duration
    endTime = track.beats[@_offsetBeats + @_numBeats - @_mixBeats] - startBeat
    gain.gain.setValueAtTime(1, @_nextStartTime + endTime)
    gain.gain.linearRampToValueAtTime(0, @_ctx.currentTime + duration)
    

    @_nextStartTime += endTime
    Meteor.setTimeout(@_main, endTime * 1000 - 100)
