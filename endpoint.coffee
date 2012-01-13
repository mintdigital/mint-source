# Generic end point class to inject any notifcation into the stream.
# Post a JSON object to /endpoint in this format:
# {
#   "message": "Message body",         // <String>: Required - the main text to be displayed.
#   "submessage": "submessage",        // <String>: Required - small lower message
#   "timestamp": "2012-01-01T00:00:00",// <String>: Optional - will use the time the post was recieved if not specified. Expects a UTC string.
#   "image": "/path/to/image.png"      // <String>: Optional - image to show on the board.
# }

events   = require('events')
fs       = require('fs')
template = require('jqtpl')
moment   = require('moment')

class EndPoint extends events.EventEmitter
  constructor: (data, redis) ->
    @redis = redis
    @data  = data
    @build()

  build: ->
    @data.timestamp = @data.timestamp || new Date().getTime()
    @data.relTime = moment(@data.timestamp).fromNow()
    @updateRedis()
    @render()

  updateRedis: ->
    @redis.lpush 'Messages', JSON.stringify(@data), =>
      @redis.ltrim 'Messages', 0, 5

  render: ->
    fs.readFile './views/_message.html', 'utf-8', (err, rawTemplate) =>
      @emit 'data', template.tmpl rawTemplate, {message: @data}

module.exports = EndPoint