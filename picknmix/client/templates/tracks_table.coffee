Template.TracksTable.helpers
  tracks: ->
    Tracks.find {},
      sort: [
        ['name', 'asc']
        ['_id' , 'asc']
      ]

