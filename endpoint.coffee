# Generic end point class to inject any notifcation into the stream.
# Post a JSON object to /endpoint in this format:
# {
#   "name": "name",               // <String>: Required - what type of notification is this?
#   "message": "Message body"     // <String>: Required - the main text to be displayed.
#   "date": "2012-01-01T00:00:00" // <String>: Optional - will use the time the post was recieved if not specified. Expects a UTC string.
#   "image": "/path/to/image.png" // <String>: Optional - image to show on the board.
# }

events   = require('events')
fs       = require('fs')
template = require('jqtpl')

class EndPoint extends events.EventEmitter
  constructor: (data, redis) ->
    @redis = redis
    @data  = data
    @updateRedis()

  updateRedis: ->
    @redis.lpush 'Commits', JSON.stringify(@data), =>
      @redis.ltrim 'Commits', 0, 5
      @render()

  render: ->
    fs.readFile './views/_message.html', 'utf-8', (err, rawTemplate) =>
      @emit 'data', template.tmpl(rawTemplate, @data)

module.exports = EndPoint