events   = require('events')
qs       = require('qs')
fs       = require('fs')
template = require('jqtpl')
async    = require('async')
moment   = require('moment')
gravatar = require('gravatar')
helpers  = require('./helpers/helpers')

if process.env.NODE_ENV == 'production'
  settings = require('./settings-heroku.coffee')
else
  settings = require('./settings.coffee')

class Github extends events.EventEmitter
  constructor: (postData, redisClient) ->
    @redis = redisClient
    @payload = JSON.parse(qs.parse(postData).payload)
    @commits = []
    @build()

  build: () ->
    project = helpers.discretify(@payload.repository.name, settings.discretionList)
    for commit in @payload.commits
      data =
        message:    commit.message
        submessage: "#{project} - #{commit.author.name}"
        timestamp:  commit.timestamp
        image:      gravatar.url(commit.author.email, {s:120})
        relTime:    moment(commit.timestamp).fromNow()
      @commits.push(data)
    @sort()

  sort: () ->
    iterator = (commit, callback) ->
      callback(null, 1 / Date.parse(commit.timestamp))
    callback = (err, result) =>
      @commits = result
    async.sortBy(@commits, iterator, callback)
    @updateRedis()
    @render()

  updateRedis: () ->
    for commit in @commits
      @redis.lpush('Messages', JSON.stringify(commit))
    @redis.ltrim('Messages', 0, 5)

  render: () ->
    fs.readFile './views/_message.html', 'utf-8', (err, rawTemplate) =>
      rendered = ''
      for commit in @commits
        rendered += template.tmpl rawTemplate, {message: commit}
      @emit 'message', rendered

module.exports = Github
