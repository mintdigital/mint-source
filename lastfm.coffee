events = require("events")
http   = require("http")

class Lastfm extends events.EventEmitter
  constructor: (opts)->
    events.EventEmitter.call this
    @user         = opts.user
    @apiKey       = opts.apiKey
    @data         = []
    @responseData = ''
    @startPolling()
    @createRequest()

  buildPath: ->
    "/2.0/?method=user.getrecenttracks&api_key=#{@apiKey}&user=#{@user}&format=json"

  onData: (data)->
    @responseData = @responseData + data
    return

  onEnd: ->
    @data = JSON.parse(@responseData)["recenttracks"]["track"]
    @responseData = ''
    @sendOutput()
    return

  startPolling: ->
    if !@refreshInterval
      @refreshInterval = setInterval (=> @createRequest()), 30e3
    return

  stopPolling: ->
    if @refreshInterval
      clearInterval @refreshInterval
    return

  createRequest: ->
    opts =
      host: 'ws.audioscrobbler.com'
      port: 80
      path: @buildPath()
      method: 'GET'
    request = http.request opts, (response)=>
      if response.statusCode is 200
        response.setEncoding 'utf8'
        response.on 'data', @onData.bind(this)
        response.on 'end', @onEnd.bind(this)
        return
      else
        @emit 'song', []
        return
    request.end()
    return

  sendOutput: ->
    output = []

    for play in @data
      if play['@attr'] and play['@attr']['nowplaying']
        output.push
          artist: play.artist['#text']
          name: play.name
    @emit 'song', output
    return

module.exports = Lastfm