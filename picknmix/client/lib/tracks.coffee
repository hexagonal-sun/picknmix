@Tracks = new Mongo.Collection
buffers = {}
Tracks.set = (id, buffer) ->
  buffers[id] = buffer

Tracks.get = (id) ->
  buffers[id]
