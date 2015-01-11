Template.TracksTable.helpers
  tracks: ->
    Tracks.find
      isSearchResults: true
    ,
      sort: [
        ['name', 'asc']
        ['_id' , 'asc']
      ]

