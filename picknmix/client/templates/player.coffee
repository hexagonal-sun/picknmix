'use strict'

Template.Player.created = ->
  @_player = new share.Player @data.audioContext,
    debug: true
  @_player.enable()


Template.Player.rendered = ->
  @_beatVisualisation = new BeatDetector.Visualisation(
      @find('#visualisation'),
      @data.audioContext)
  @autorun =>
    if (track = @_player.getTrack())?
      beatManager = Tracks.get track._id
      @_beatVisualisation.render beatManager


Template.Player.destroyed = ->
  @_player.disable()


Template.Player.helpers
  track: ->
    Template.instance()._player.getTrack()

