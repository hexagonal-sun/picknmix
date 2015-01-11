Template.Decks.created = ->
  @_audioContext = new AudioContext

Template.Decks.helpers
  audioContext: ->
    Template.instance()._audioContext
