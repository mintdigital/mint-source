# Songs.js
# returns App.Songs for visualising currently playing songs.

window.App = {} unless window.App

App.Songs =
  init: () ->
    @$nowPlaying = $('div.now-playing')
    @$text = @$nowPlaying.find 'marquee'

    @$nowPlaying.removeClass('hidden').click(=>@close())
    @parseResponse(false)
    @listen()

  listen: ->
    App.socket.on 'lastfm', (msg) => @parseResponse(msg)

  stopListening: () ->
    App.socket.removeAllListeners 'lastfm'

  close: () ->
    @stopListening()
    @$nowPlaying.addClass('hidden')

  parseResponse: (msg) ->
    if msg[0]
      text = "\u266b #{msg[0].artist} - #{msg[0].name} \u266b"
    else
      text = 'Nothing playing... quick, get some tunes on!'
    @$text.text text
    return

