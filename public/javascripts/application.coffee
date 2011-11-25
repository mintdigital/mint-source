window.App = {} unless window.App

$ () ->
  App.socket = io.connect window.location.origin

  setDates = () ->
    $('.commit .time').each (i, elem) ->
      $elem     = $(elem)
      timestamp = $elem.data 'timestamp'
      $elem.text moment(timestamp).fromNow()

  window.setInterval setDates, 60e3

  App.socket.on 'connect', ->
    App.Health().init()

    App.socket.on 'message', (commit) ->
      $('#wrapper').prepend(commit)
      $('#wrapper .commit:gt(9)').remove()

    if App.songsEnabled
      App.Songs.init()

  reloadCSS = () ->
    `var h,a,f,g;a=window.document.getElementsByTagName('link');for(h=0;h<a.length;h++){f=a[h];if(f.rel.toLowerCase().match(/stylesheet/)&&f.href){g=f.href.replace(/(&|\?)forceReload=\d+/,'');f.href=g+(g.match(/\?/)?'&':'?')+'forceReload='+(new Date().valueOf());}}`
    console.log('Reloading CSS...') if window.console and window.console.log

  $(window.document).keyup (ev) ->
    # Enables hitting alt-W to refresh CSS in every browser.
    # Source: http://gist.github.com/221905
    reloadCSS() if ev.which is 87 and ev.altKey