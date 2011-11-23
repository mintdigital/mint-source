# Songs.js
# returns App.Songs for visualising currently playing songs.

window.App = {} unless window.App

App.Songs =
  init: (socketObject) ->
    $('div.now-playing').removeClass('hidden')
    @$nowPlaying = $ 'div.now-playing marquee'
    @socket = socketObject

    @parseResponse(false)
    @listen()

  listen: ->
    @socket.on 'lastfm', (msg) => @parseResponse(msg)

  stopListening: () ->
    @socket.off 'lastfm'

  parseResponse: (msg) ->
    if msg[0]
      text = "\u266b #{msg[0].artist} - #{msg[0].name} \u266b"
    else
      text = 'Nothing playing... quick, get some tunes on!'
    @$nowPlaying.text text
    return

