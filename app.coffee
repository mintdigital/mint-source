connect     = require('connect')
express     = require('express')
url         = require('url')
fs          = require('fs')
qs          = require('qs')
async       = require('async')
moment      = require('moment')
gravatar    = require('gravatar')
template    = require('jqtpl')
Github      = require('./github')
Jenkins     = require('./jenkins')
Lastfm      = require('./lastfm')
EndPoint    = require('./endpoint')
helpers     = require('./helpers/helpers')
settings = {}
redis    = {}
app = module.exports = express.createServer()
io  = require('socket.io').listen(app)

# Configuration

app.configure( ()->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'html')
  app.set('view cache', false)
  app.register('.html', require('jqtpl').express)
  app.use(app.router)
  app.use(express.static(__dirname + '/public'))
  return
)

app.configure('development', () ->
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
  settings = require('./settings')
  redis    = require('redis').createClient()
  return
)

app.configure('production', () ->
  app.use(express.errorHandler())
  settings = require('./settings-heroku')
  # Redis to go on Heroku, local Redis in development
  rtg   = url.parse(process.env.REDISTOGO_URL)
  redis = require('redis').createClient(rtg.port, rtg.hostname)
  redis.auth(rtg.auth.split(":")[1])
  # No websockets for Heroku
  io.configure () ->
    io.set('transports', ['xhr-polling'])
    io.set('polling duration', 10)
  return
)

app.helpers({
  gravatar:gravatar,
  moment:moment
})

# get discretionList from Redis
settings.discretionList = []
getDiscretionList = (listName) ->
  redis.lrange listName, 0, -1, (err, replies) ->
    for reply in replies
      settings.discretionList.push(JSON.parse(reply))

getDiscretionList 'Discretions'

# Middleware functions

basicAuth = (req, res, next) ->
  if settings.auth.enabled
    connect.basicAuth(settings.auth.user, settings.auth.pass)(req, res, next)
  else
    next()

ipWhitelist = (req, res, next) ->
  remote = req.connection.remoteAddress
  if settings.jenkins.ip and remote != settings.jenkins.ip
    res.writeHead 403
    res.end '403 Forbidden'
    console.log "IP whitelist: blocked request to '#{req.url}' from '#{remote}'"
  else
    console.log "IP whitelist: allowed request to '#{req.url}' from '#{remote}'"
    next()

# Routes

app.get('/javascripts/:resource.js', (req, res) ->
  resource = req.params.resource
  helpers.compile resource, (compiled) ->
    res.contentType('application/javascript').send(compiled)
)

app.get('/', basicAuth, (req, res) ->
  messages = []
  statuses = []
  getStatuses = ->
    redis.hgetall('Jenkins', (err, replies) ->
      for project, status of replies
        project = helpers.discretify(project, settings.discretionList)
        if status != 'SUCCESS'
          statuses.push({project: project, status: status})
      res.header('Cache-Control', 'no-cache')
      console.log(messages)
      res.render('index', {
        title: 'Mint Source',
        messages: messages,
        statuses: statuses,
        songsEnabled: settings.lastfm.enabled
      })
    )
  app.emit 'pageload'
  redis.lrange('Messages', 0, 5, (err, replies) ->
    for reply in replies
      reply = JSON.parse(reply)
      reply.project = helpers.discretify(reply.project, settings.discretionList)
      reply.relTime = moment(reply.timestamp).fromNow()
      messages.push(reply)

    async.sortBy(messages, (message, callback) ->
      callback(null, 1 / Date.parse(message.timestamp))
    ,(err, results) ->
      messages = results
      getStatuses()
    )
  )
)

app.post('/github_prh', basicAuth, (req, res) ->
  # GitHub post recieve hook
  # Remember to post to http://user:password@your-app/github_prh
  # if using basic auth - https://github.com/blog/237-basic-auth-post-receives
  body = ''
  req.on('data', (data) -> body += data )
  req.on('end', () ->
    g = new Github(body, redis)
    g.on('message', (data) -> io.sockets.emit('message', data))
    res.writeHead(200, {'Content-Type': 'text/html'})
    res.end('OK')
  )
)

app.post('/jenkins_pbh', ipWhitelist, (req, res) ->
  # Jenkins post build hook
  # Requires https://wiki.jenkins-ci.org/display/JENKINS/Notification+Plugin
  if !settings.jenkins.enabled
    console.log('Jenkins disabled')
    res.writeHead(404)
    res.end()
  else
    body = ''
    req.on('data', (data) ->
      body += data
    )
    req.on('end', () ->
      post = JSON.parse(body)
      return unless post.build.phase == 'FINISHED'
      post.name = helpers.discretify(post.name, settings.discretionList)
      j = new Jenkins(post, redis)
      j.on('data', (data) -> io.sockets.emit('jenkins', data))
      return
    )
    res.writeHead(200, {'Content-Type': 'text/html'})
    res.end('OK')
)

app.post '/endpoint', (req,res) ->
  # Generic endpoint, send JSON here, show it on the status board
  body = ''
  req.on 'data', (data) -> body += data
  req.on 'end', ->
    post = JSON.parse(body)
    e = new EndPoint(post, redis)
    e.on('data', (data) -> io.sockets.emit('message', data))
    res.writeHead 200, {'Content-Type': 'text/html'}
    res.end 'OK'

if settings.lastfm.enabled
  lfm = new Lastfm({
    user:   settings.lastfm.user
    apiKey: settings.lastfm.apiKey
  })
  app.on 'pageload', () -> lfm.createRequest()
  lfm.on('song', (data) -> io.sockets.emit('lastfm', data))

app.listen(process.env.PORT || 1337)
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env)
