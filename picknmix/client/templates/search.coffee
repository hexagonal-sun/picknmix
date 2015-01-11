Template.Search.created = ->
  @_api = new Spotify.WebAPI

Template.Search.events
  'click #search-btn': (event, template) ->
    event.preventDefault()
    $query = template.$('#search-query')
    query = $query.val()
    $query.val ''
    api = template._api
    fut = api.search query, types: api.TRACK
    template.autorun (computation) ->
      if fut.isDone()
        computation.stop()
        if (result = fut.getResult())?
          onSearchResults result.data


onSearchResults = (results) ->
  # Clear old search results
  Tracks.update
    isSearchResults: true
  ,
    $set:
      isSearchResults: false
  ,
    multi: true

  # Stop if no track were found
  unless (rawTracks = results.tracks?.items)?
    return

  for rawTrack in rawTracks
    Tracks.upsert rawTrack.id,
      $set:
        name: rawTrack.name
        artist: rawTrack.artists[0].name
        previewUrl: rawTrack.preview_url
        isSearchResults: true

