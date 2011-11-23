# Get settings from Heroku environment variables
exports.auth =
  enabled: process.env.AUTH_ENABLED    || false
  user:    process.env.AUTH_USER       || ''
  pass:    process.env.AUTH_PASS       || ''

exports.jenkins =
  enabled: process.env.JENKINS_ENABLED || false
  ip:      process.env.JENKINS_IP      || false

exports.lastfm =
  enabled: process.env.LASTFM_ENABLED  || false
  apiKey:  process.env.LASTFM_KEY      || ''
  user:    process.env.LASTFM_USER     || ''