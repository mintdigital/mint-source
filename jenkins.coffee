util   = require('util')
events = require('events')
https  = require('https')
url    = require('url')

class Jenkins extends events.EventEmitter
  constructor: (data, redisClient) ->
    events.EventEmitter.call(this)
    @redis = redisClient
    @project = data.name
    @status = data.build.status

    @parseStatus()

  parseStatus: () ->
    prevStatus = ''

    statusLogic = =>
      @status = 'RECENT FAILURE' if prevStatus == 'FAILURE' and @status == 'SUCCESS'
      @redis.hset('Jenkins', @project, @status)
      @sendOutput()

    if @redis.hexists('Jenkins', @project)
      @redis.hget('Jenkins', @project, (err, result) ->
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

