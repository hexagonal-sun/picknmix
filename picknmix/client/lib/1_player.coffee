'use strict'

class share.Player
  constructor: (@_ctx, options = {}) ->
    @_computation   = null
    @_nextStartTime = null
    @_timeoutId     = null
    @_track         = ReactiveVar()
    @_latencySec    = options.latency ? 0.1
    @_bpm           = ReactiveVar options.bpm ? 120
    @_startBeat     = ReactiveVar options.startBeat ? 2
    @_numPlayBeats  = ReactiveVar options.numPlayBeats ? 10
    @_numMixBeats   = ReactiveVar options.numMixBeats ? 2
    @_debug         = options.debug ? false

  getBpm: =>
    @_bpm.get()

  getNumPlayBeats: =>
    @_numPlayBeats.get()

  getNumMixBeats: =>
    @_numMixBeats.get()

  getNumBeats: =>
    @getNumPlayBeats() + @getNumMixBeats() * 2

  getSpb: =>
    60 / @getBpm()

  getStartBeat: =>
    @_startBeat.get()

  getStopBeat: =>
    @getStartBeat() + @getNumBeats()

  getTrack: =>
    @_track.get()

  enable: =>
    @_trySchedule()

  disable: =>
    Meteor.clearTimeout @_timeoutId
    @_timeoutId = null
    @_stopComputation()

  _trySchedule: =>
    @_computation = Tracker.autorun =>
      if @_tryFindTrack()?
        @_stopComputation()
        @_schedule()

  _stopComputation: =>
    @_computation?.stop()
    @_computation = null

  _schedule: =>
    unless (track = @_tryFindTrack())?
      @_trySchedule()
      return

    @_track.set track

    # Source buffer
    sourceBuffer = Tracks.get(track._id).getAudioSample().buffer

    # Playback rate
    playbackRate = @getBpm() / track.bpm

    # Beats
    startBeat = @getStartBeat()
    stopBeat = @getStopBeat()
    numMixBeats = @getNumMixBeats()

    getOffsetAtBeat = (beatIndex) ->
      playbackRate * track.beats[beatIndex]

    # Globa times
    currentTime = @_ctx.currentTime
    @_nextStartTimeSec ?= currentTime + @_latencySec

    # Source offsets, times and duration
    sourceStartOffsetSec = getOffsetAtBeat startBeat
    sourceStopOffsetSec = getOffsetAtBeat stopBeat
    sourceStartTimeSec = @_nextStartTimeSec
    sourceStopTimeSec = sourceStartTimeSec + sourceStopOffsetSec
    sourceDurationSec = sourceStopOffsetSec - sourceStartOffsetSec

    # Source mix-in and mix-out offsets and times
    sourceMixInStopOffsetSec = getOffsetAtBeat startBeat + numMixBeats
    sourceMixOutStartOffsetSec = getOffsetAtBeat stopBeat - numMixBeats
    sourceMixInStopTimeSec = sourceStartTimeSec + sourceMixInStopOffsetSec - sourceStartOffsetSec
    sourceMixOutStartTimeSec = sourceStartTimeSec + sourceMixOutStartOffsetSec - sourceStartOffsetSec

    # Source
    source = @_ctx.createBufferSource()
    source.buffer = sourceBuffer
    source.playbackRate.value = playbackRate
    source.start sourceStartTimeSec, sourceStartOffsetSec, sourceDurationSec

    # Gain
    gain = @_ctx.createGain()
    gain.gain.value = 0
    gain.gain.setValueAtTime 0, sourceStartTimeSec
    gain.gain.linearRampToValueAtTime 1, sourceMixInStopTimeSec
    gain.gain.setValueAtTime 1, sourceMixOutStartTimeSec
    gain.gain.linearRampToValueAtTime 0, sourceStopTimeSec

    # Connections
    source.connect gain
    gain.connect @_ctx.destination

    # Reschedule
    @_nextStartTimeSec = sourceMixOutStartTimeSec
    delaySec = sourceMixOutStartOffsetSec - sourceStartOffsetSec - @_latencySec
    @_timeoutId = Meteor.setTimeout @_schedule, 1000 * delaySec

    if @_debug
      console.log """
        Current time: #{ currentTime }s
        Next start time: #{ @_nextStartTimeSec }s
        Track: #{ track.name }
          Source:
            Offsets:
              Start: #{ sourceStartOffsetSec }s
              Stop: #{ sourceStopOffsetSec }s
            Times:
              Start: #{ sourceStartTimeSec }s
              Mix-in stop: #{ sourceMixInStopTimeSec }s
              Mix-out Start: #{ sourceMixOutStartTimeSec }s
              Stop: #{ sourceStopTimeSec }s
            Duration: #{ sourceDurationSec }s
        """

  _tryFindTrack: =>
    cursor = Tracks.find
      numBeats:
        $gte: @getNumBeats()
    tracks = cursor.fetch()
    if tracks.length > 1 and (track = @_track.get())?
      tracks = (t for t in tracks when t._id != track._id)
    if tracks.length != 0
      tracks[Math.floor tracks.length * Math.random()]

