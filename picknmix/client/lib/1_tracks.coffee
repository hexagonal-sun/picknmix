@Tracks = new Mongo.Collection null

beatManagers = {}

Tracks.get = (id) ->
  beatManagers[id]

Tracks.set = (id, beatManager) ->
  beatManagers[id] = beatManager

