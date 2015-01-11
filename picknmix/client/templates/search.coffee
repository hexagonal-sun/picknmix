Template.Search.created = ->
  @_api = new Spotify.WebAPI
  
Template.Search.events
  'click #search-btn': (event, template) ->
    event.preventDefault()
    {_api: api} = template
    searchText = template.$('#song-search').val()
    fut = api.search(searchText, types: api.TRACK)
    template.autorun ->
      if (result = fut.getResult())?
        onSearchResults(result.data)

onSearchResults = (results) ->
  unless (rawTracks = results.tracks)?
    return

  for rawTrack in rawTracks.items
    Tracks.upsert rawTrack.id,
      $set:
        name: rawTrack.name
        artist: rawTrack.artists[0].name
        previewUrl: rawTrack.preview_url
