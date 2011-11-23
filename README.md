Mint Source
=========

A simple Node.js status board showing:

- Recent Github commits
- Jenkins CI build status
- Current song playing through Last.fm

Dependencies
------------

- node.js 0.4
- npm
  - To install run: `curl http://npmjs.org/install.sh | sh`
- Redis (local install for development)
- Heroku account (for production deploy)

Development
------------

1. Install dependencies `npm install`
2. Copy `settings.coffee.example` to `settings.coffee`.
3. Add relevant details to the settings.coffee
4. Start redis `redis-server`
5. Run the app `node index.js`
6. Visit `localhost:1337` in a browser.

Deploy to Heroku
------------

1. Create a new app on Heroku: `heroku create appname --stack cedar`
2. Deploy to heroku `git push heroku master`
3. Scale the web process on Heroku `heroku ps:scale web=1`
4. Add Redis to go to your app `heroku addons:add redistogo`
5. Add your app settings:
  - `heroku config:add NODE_ENV=production`
  - `heroku config:add AUTH_ENABLED=true` => enable/disable basic HTTP auth
  - `heroku config:add AUTH_USER=username` => optional basic auth username
  - `heroku config:add AUTH_PASS=password` => optional basic auth password
  - `heroku config:add JENKINS_ENABLED=true` => enable build monitoring with Jenkins?
  - `heroku config:add JENKINS_IP=10.20.30.40` => set if you'd like to IP filter the Jenkins receive action
  - `heroku config:add LASTFM_ENABLED=true` => optional - show current Last.fm song
  - `heroku config:add LASTFM_KEY=apikey` => your Last.fm api key
  - `heroku config:add LASTFM_USER=username` => the Last.fm account you'd like to track

Wait, I have NDA projects which I can't display on my status board!
---------------

We totally have your back, substitute sensitive names by adding them to Redis (there will be a page to administer this eventually):

    LPUSH Discretions "{\"orig\":\"secret-name\",\"subs\":\"public-name\"}"

Testing locally
---------------

You can manually add mock Github post receive hook data to Redis.

    redis-cli

    LPUSH Commits "{\"message\":\"update pricing a tad\",\"project\":\"github\",\"timestamp\":\"2008-02-15T14:36:34-08:00\",\"author\":\"Chris Wanstrath\"}"

    LPUSH Commits "{\"message\":\"woo\! it works\",\"project\":\"github\",\"timestamp\":\"2011-02-15T14:36:34-08:00\",\"author\":\"Chris Wanstrath\"}"
