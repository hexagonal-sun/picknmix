'use strict'

class share.Scheduler
  constructor: (@_ctx) ->
    @_latency      = 0.1
    @_schedulers   = ReactiveVar []
    @_rescheduleId = null
    @_track        = ReactiveVar null

    @_computation  = Tracker.autorun @_trySchedule

  disable: =>
    Meteor.clearTimeout @_timeoutId
    @_rescheduleId = null
    @_stopComputation()
    @_ctx = null

  getTrack: =>
    if _.isEmpty(trackSchedulers = @_schedulers.get())
      @_track.set null
    else
      current = @_ctx.getCurrentTime()
      trackScheduler = _.min trackSchedulers, (ts) ->
        Math.abs ts.getCtxStart() - current
      trackScheduler.getTrack()

  _trySchedule: =>
    Tracker.nonreactive @_pruneTrackSchedulers
    return unless (track = @_findTrack())?
    @_stopComputation()
    ctxStart = @_schedule track
    delay = 1000 * (ctxStart - @_ctx.getCurrentTime())
    @_rescheduleId = Meteor.setTimeout @_trySchedule, delay

  _findTrack: =>
    _.sample Tracks.find(numBeats: $gte: @_ctx.getNumBufBeats()).fetch()

  _schedule: (track) =>
    ctxStart = @_findInitialCtxStart()
    ts = share.TrackScheduler @_ctx, track
    ts.schedule ctxStart
    schedulers = @_schedulers.get()
    schedulers.push ts
    @_schedulers.set schedulers
    ctxStart

  _findInitialCtxStart: =>
    if (last = _.last @_schedulers.get())?
      last.getCtxMixOutStart()
    else
      @_ctx.getCurrentTime() + @_latency

  _pruneTrackSchedulers: =>
    schedulers = @_schedulers.get()
    unless _.isEmpty schedulers
      current = @_ctx.getCurrentTime()
      @_schedulers.set(ts for ts in schedulers when ts.getCtxStop() > current)

  _stopComputation: =>
    @_computation?.stop()
    @_computation = null

