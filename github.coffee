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
    branch = @payload.ref.replace('refs/heads/', '')
    for commit in @payload.commits
      data =
        message:   commit.message
        timestamp: commit.timestamp
        author:    commit.author.name
        project:   project
        branch:    branch
        image:     gravatar.url(commit.author.email, {s:120})
        relTime:   moment(commit.timestamp).fromNow()
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
      @redis.lpush('Commits', JSON.stringify(commit))
    @redis.ltrim('Commits', 0, 5)

  render: () ->
    fs.readFile('./views/_commit.html', 'utf-8', (err, rawTemplate) =>
      @emit('message', template.tmpl(rawTemplate, @commits))
    )

module.exports = Github
