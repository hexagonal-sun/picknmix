'use strict'

Template.Player.created = ->
  ctx = new share.SchedulerContext @data.audioContext,
    debug: false
  @_scheduler = new share.Scheduler ctx


Template.Player.rendered = ->
  @_beatVisualisation = new BeatDetector.Visualisation(
      @find('#visualisation'),
      @data.audioContext)

  @autorun =>
    if (track = @_scheduler.getTrack())?
      @_beatVisualisation.render Tracks.get track._id


Template.Player.destroyed = ->
  @_scheduler.disable()


Template.Player.helpers
  track: ->
    Template.instance()._scheduler.getTrack()

