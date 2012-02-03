window.App = {} unless window.App

$ () ->
  App.socket = io.connect window.location.origin

  App.socket.on 'message', (commit) ->
    $('#wrapper').prepend(commit)
    $('#wrapper .commit:gt(9)').remove()

  App.socket.on 'disconnect', () ->
    # Attempt to reconnect after 5 minutes if the connection dies (e.g. on deploy)
    reconnect = () ->
      if !App.socket.socket.open
        App.socket = io.connect window.location.origin

    window.setTimeout reconnect, 300e3 # 5 min

  setDates = () ->
    $('.commit .time').each (i, elem) ->
      $elem     = $(elem)
      timestamp = $elem.data 'timestamp'
      $elem.text moment(timestamp).fromNow()

  window.setInterval setDates, 30e3

  App.socket.on 'connect', ->
    App.Health().init()
    App.Songs.init() if App.songsEnabled

  reloadCSS = () ->
    `var h,a,f,g;a=window.document.getElementsByTagName('link');for(h=0;h<a.length;h++){f=a[h];if(f.rel.toLowerCase().match(/stylesheet/)&&f.href){g=f.href.replace(/(&|\?)forceReload=\d+/,'');f.href=g+(g.match(/\?/)?'&':'?')+'forceReload='+(new Date().valueOf());}}`
    console.log('Reloading CSS...') if window.console and window.console.log

  $(window.document).keyup (ev) ->
    # Enables hitting alt-W to refresh CSS in every browser.
    # Source: http://gist.github.com/221905
    reloadCSS() if ev.which is 87 and ev.altKey