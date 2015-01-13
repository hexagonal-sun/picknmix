'use strict'

class share.TrackScheduler
  constructor: (ctx, track) ->
    unless this instanceof share.TrackScheduler
      return new share.TrackScheduler arguments...
    @_ctx            = ctx
    @_ctxMixOutStart = null
    @_ctxStart       = ReactiveVar null
    @_ctxStop        = null
    @_gain           = null
    @_playbackRate   = ReactiveVar null
    @_source         = null
    @_track          = track

  getCtxStart:       => @_ctxStart.get()
  getCtxStop:        => @_ctxStop
  getCtxMixOutStart: => @_ctxMixOutStart
  getPlaybackRate:   => @_playbackRate.get()
  getTrack:          => @_track

  schedule: (ctxStart) =>
    @_unschedule()
    @_setCtxStart ctxStart
    @_setPlaybackRate()
    bufTimes = @_calcBufTimes()
    srcTimes = @_calcSrcTimes bufTimes
    ctxTimes = @_calcCtxTimes srcTimes
    @_logTimes bufTimes, srcTimes, ctxTimes
    @_setCtxMixOutStart ctxTimes.mixOutStart
    @_setCtxStop ctxTimes.stop
    @_createSource bufTimes, srcTimes, ctxTimes
    @_createGain ctxTimes
    @_connect()

  _setCtxStart: (ctxStart) =>
    @_ctxStart.set ctxStart

  _setPlaybackRate: =>
    @_playbackRate.set @_ctx.getBpm() / @_track.bpm

  _calcBufTimes: =>
    startBeat    = @_ctx.getStartBeat()
    numPlayBeats = @_ctx.getNumPlayBeats()
    numMixBeats  = @_ctx.getNumMixBeats()
    numBeats     = @_ctx.getNumBufBeats()
    share.Timings
      start:       @_getBufTimeAt startBeat
      mixInStop:   @_getBufTimeAt startBeat + numMixBeats
      mixOutStart: @_getBufTimeAt numBeats  - numMixBeats
      stop:        @_getBufTimeAt numBeats

  _getBufTimeAt: (beatIndex) =>
    @_track.beats[beatIndex] / @getPlaybackRate()

  _calcSrcTimes: (bufTimes) =>
    share.Timings
      mixInStop:   bufTimes.mixInStop   - bufTimes.start
      mixOutStart: bufTimes.mixOutStart - bufTimes.start
      stop:        bufTimes.duration

  _calcCtxTimes: (srcTimes) =>
    ctxStart = @getCtxStart()
    share.Timings
      start:       ctxStart
      mixInStop:   ctxStart + srcTimes.mixInStop
      mixOutStart: ctxStart + srcTimes.mixOutStart
      stop:        ctxStart + srcTimes.stop

  _createSource: (bufTimes, srcTimes, ctxTimes) =>
    @_source = @_ctx.createBufferSource()
    @_source.playbackRate.value = @getPlaybackRate()
    @_source.buffer = @_getBuffer()
    @_source.onended = @_onEnded
    @_source.start ctxTimes.start, bufTimes.start, srcTimes.duration

  _getBuffer: =>
    Tracks.get(@_track._id).getAudioSample().buffer

  _setCtxMixOutStart: (ctxMixOutStart) =>
    @_ctxMixOutStart = ctxMixOutStart

  _setCtxStop: (ctxStop) =>
    @_ctxStop = ctxStop

  _createGain: (ctxTimes) =>
    @_gain = @_ctx.createGain()
    @_gain.gain.value = 0
    @_gain.gain.setValueAtTime 0, ctxTimes.start
    @_gain.gain.linearRampToValueAtTime 1, ctxTimes.mixInStop
    @_gain.gain.setValueAtTime 1, ctxTimes.mixOutStart
    @_gain.gain.linearRampToValueAtTime 0, ctxTimes.stop

  _connect: =>
    @_source.connect @_gain
    @_gain.connect @_ctx.getDestination()

  _onEnded: =>
    @_unschedule()
    @_ctx = @_track = null

  _unschedule: =>
    @_gain?.disconnect()
    @_gain = null
    try @_source?.stop()
    @_source?.disconnect()
    @_source = null

  _logTimes: (bufTimes, srcTimes, ctxTimes) =>
    Tracker.nonreactive =>
      if @_ctx.getDebug()
        parts = [ "Track: #{ @_track.name }" ]
        parts.push '\n\nBuffer:\n', bufTimes.toString()
        parts.push '\n\nSource:\n', srcTimes.toString()
        parts.push '\n\nContext:\n', ctxTimes.toString()
        console.log parts.join ''

