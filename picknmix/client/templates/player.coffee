'use strict'

Template.Player.created = ->
  @_player = new share.Player @data.audioContext,
    debug: true
  @_player.enable()

Template.Player.destroyed = ->
  @_player.disable()

Template.Player.helpers
  track: ->
    Template.instance()._player.getTrack()

