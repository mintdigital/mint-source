util   = require('util')
events = require('events')
https  = require('https')
url    = require('url')
if process.env.REDISTOGO_URL
  rtg   = url.parse(process.env.REDISTOGO_URL)
  redis = require('redis').createClient(rtg.port, rtg.hostname)
  redis.auth(rtg.auth.split(":")[1])
else
  redis = require('redis').createClient()

class Jenkins extends events.EventEmitter
  constructor: (data) ->
    events.EventEmitter.call(this)
    @project = data.name
    @status = data.build.status

    @parseStatus()

  parseStatus: () ->
    prevStatus = ''

    statusLogic = =>
      redis.hset('Jenkins', @project, @status)
      @status = 'RECENT FAILURE' if prevStatus == 'FAILURE' and @status == 'SUCCESS'
      @sendOutput()

    if redis.hexists('Jenkins', @project)
      redis.hget('Jenkins', @project, (err, result) ->
        prevStatus = result
        statusLogic()
      )
    else
      statusLogic()

  sendOutput: () ->
    if @status is 'FAILURE' or 'RECENT FAILURE'
      output = {
        project: @project,
        status: @status
      }
      console.log('Sending: ', output)
      @emit('data', output);
    return

module.exports = Jenkins

