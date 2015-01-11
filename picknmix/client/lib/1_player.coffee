'use strict'

class share.Player
  constructor: (@_ctx, options = {}) ->
    @_computation   = null
    @_nextStart     = null
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

  setBpm: (bpm) =>
    @_bpm.set bpm

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

    playbackRate   = @getBpm() / track.bpm

    getBufTimeAt   = (beatIndex) -> playbackRate * track.beats[beatIndex]

    startBeat      = @getStartBeat()
    stopBeat       = @getStopBeat()
    numMixBeats    = @getNumMixBeats()

    bufStart       = getBufTimeAt startBeat
    bufMixInStop   = getBufTimeAt startBeat + numMixBeats
    bufMixOutStart = getBufTimeAt stopBeat - numMixBeats
    bufStop        = getBufTimeAt stopBeat
    bufDuration    = bufStop - bufStart

    srcStart       = 0
    srcMixInStop   = bufMixInStop - bufStart
    srcMixOutStart = bufMixOutStart - bufStart
    srcStop        = bufDuration
    srcDuration    = srcStop - srcStart

    ctxCurrent     = @_ctx.currentTime
    ctxStart       = @_nextStart ? ctxCurrent + @_latencySec
    ctxMixInStop   = ctxStart + srcMixInStop
    ctxMixOutStart = ctxStart + srcMixOutStart
    ctxStop        = ctxStart + srcStop

    source = @_ctx.createBufferSource()
    source.buffer = Tracks.get(track._id).getAudioSample().buffer
    source.playbackRate.value = playbackRate
    source.start ctxStart, bufStart, srcDuration

    gain = @_ctx.createGain()
    gain.gain.value = 0
    gain.gain.setValueAtTime 0, ctxStart
    gain.gain.linearRampToValueAtTime 1, ctxMixInStop
    gain.gain.setValueAtTime 1, ctxMixOutStart
    gain.gain.linearRampToValueAtTime 0, ctxStop

    source.connect gain
    gain.connect @_ctx.destination

    # Reschedule
    @_nextStart = ctxMixOutStart
    delaySec = ctxMixOutStart - ctxCurrent - @_latencySec
    @_timeoutId = Meteor.setTimeout @_schedule, 1000 * delaySec

    if @_debug
      console.log """
        Current time: #{ ctxCurrent.toFixed 1 }s
        Scheduling delay: #{ delaySec.toFixed 1}s
        Next start time: #{ @_nextStart.toFixed 1 }s
        Track: #{ track.name }
        Buffer:
          Start: #{ bufStart.toFixed 1 }s
          Mix-in Stop: #{ bufMixInStop.toFixed 1 }s
          Mix-out Start: #{  bufMixOutStart.toFixed 1}s
          Stop: #{ bufStop.toFixed 1 }s
          Duration: #{ bufDuration.toFixed 1 }s
        Source:
          Start #{ srcStart.toFixed 1 }s
          Mix-in Stop: #{ srcMixInStop.toFixed 1 }s
          Mix-out Start: #{ srcMixOutStart.toFixed 1 }s
          Stop: #{ srcStop.toFixed 1 }s
          Duration: #{ srcDuration.toFixed 1 }s
        Context:
          Start: #{ ctxStart.toFixed 1 }s
          Mix-in: #{ ctxMixInStop.toFixed 1 }s
          Mix-out: #{ ctxMixOutStart.toFixed 1 }s
          Stop: #{ ctxStop.toFixed 1 }s
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

