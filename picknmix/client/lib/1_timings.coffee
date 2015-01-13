'use strict'

class share.Timings
  constructor: (options = {}) ->
    unless this instanceof share.Timings
      return new share.Timings options
    @start       = options.start       ? 0
    @mixInStop   = options.mixInStop   ? 0
    @mixOutStart = options.mixOutStart ? null
    @stop        = options.stop        ? null
    @duration    = if @start? and @stop? then @stop - @start else null

  toString: =>
    push = (name, time) ->
      lines.push "#{ name }: #{ time.toFixed 1 }s" if time?
    lines = []
    push 'Start', @start
    push 'Mix-in stop', @mixInStop
    push 'Mix-out start', @mixOutStart
    push 'Stop', @stop
    push 'Duration', @duration
    lines.join '\n'

