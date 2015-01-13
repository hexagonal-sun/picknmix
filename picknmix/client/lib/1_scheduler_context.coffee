'use strict'

class share.SchedulerContext
  constructor: (@_audioContext, options = {}) ->
    @_bpm          = ReactiveVar options.bpm          ? 120
    @_startBeat    = ReactiveVar options.startBeat    ? 2
    @_numPlayBeats = ReactiveVar options.numPlayBeats ? 10
    @_numMixBeats  = ReactiveVar options.numMixBeats  ? 2
    @_debug        = ReactiveVar options.debug        ? false

  toString: => """
    BPM:        #{ @_bpm.get() }
    Start beat: #{ @_startBeat.get() }
    Play beats: #{ @_numPlayBeats.get() }
    Mix beats:  #{ @_numMixBeats.get() }
    Debug:      #{ @_debug.get() }
  """


  # == AudioContext delegates ================================================

  createBufferSource: => @_audioContext.createBufferSource()
  createGain:         => @_audioContext.createGain()
  getCurrentTime:     => @_audioContext.currentTime
  getDestination:     => @_audioContext.destination


  # == Base getters ==========================================================

  getBpm:          => @_bpm.get()
  getStartBeat:    => @_startBeat.get()
  getNumPlayBeats: => @_numPlayBeats.get()
  getNumMixBeats:  => @_numMixBeats.get()
  getDebug:        => @_debug.get()


  # == Base setters ==========================================================

  setBpm:          (bpm)          => @_bpm.set bpm
  setStartBeat:    (startBeat)    => @_startBeat.set startBeat
  setNumPlayBeats: (numPlayBeats) => @_numPlayBeats.set numPlayBeats
  setNumMixBeats:  (numMixBeats)  => @_numMixBeats.set numMixBeats
  setDebug:        (debug)        => @_debug.set debug


  # == Derivated getters =====================================================

  getNumSrcBeats: =>
    2 * @getNumMixBeats() + @getNumPlayBeats()

  getNumBufBeats: =>
    @getStartBeat() + @getNumSrcBeats()

