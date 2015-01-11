@Tracks = new Mongo.Collection null

buffers = {}

Tracks.set = (id, buffer) ->
  buffers[id] = buffer

Tracks.get = (id) ->
  buffers[id]

