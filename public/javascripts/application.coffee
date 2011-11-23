window.App = {} unless window.App

$ () ->
  socket = io.connect window.location.origin

  setDates = () ->
    moment.lang('fr')
    $(".commit").each((index, elm) ->
      timeElm = $(".message .time", elm)
      timeElm.html(moment(timeElm.attr("data-time-stamp")).fromNow())
    )
  setDates();

  socket.on 'connect', ->
    App.Health().init(socket)

    socket.on 'message', (commit) ->
      timeElm = $(".message .time", commit)
      timeElm.html(moment(timeElm.attr("data-time-stamp")).fromNow())
      $('#wrapper').prepend(commit)
      $('#wrapper .commit:gt(9)').remove()

    if App.songsEnabled
      App.Songs.init(socket)

  reloadCSS = () ->
    `var h,a,f,g;a=window.document.getElementsByTagName('link');for(h=0;h<a.length;h++){f=a[h];if(f.rel.toLowerCase().match(/stylesheet/)&&f.href){g=f.href.replace(/(&|\?)forceReload=\d+/,'');f.href=g+(g.match(/\?/)?'&':'?')+'forceReload='+(new Date().valueOf());}}`
    console.log('Reloading CSS...') if window.console and window.console.log

  $(window.document).keyup (ev) ->
    # Enables hitting alt-W to refresh CSS in every browser.
    # Source: http://gist.github.com/221905
    reloadCSS() if ev.which is 87 and ev.altKey