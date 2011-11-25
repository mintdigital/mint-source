# Health.coffee
# returns App.Health for visualising Jenkins health.

window.App = {} unless window.App

App.Health = () ->
  _cache = {}
  Health =
    init: () ->
      @$body          = $('body')
      @$failWrapper   = $('.fail-wrapper')
      @$failText      = @$failWrapper.find('.fail-message')

      @bootstrap() if App.JenkinsBootstrap.length > 0
      @listen()

    listen: () ->
      App.socket.on 'jenkins', (msg) => @parseMessage(msg)

    bootstrap: () ->
      for status in App.JenkinsBootstrap
        @parseMessage(status)

    stopListening: () ->
      App.socket.off 'jenkins'

    get: (project) ->
      _cache[project]

    set: (project, status) ->
      _cache[project] = status

    parseMessage: (msg) ->
      @set(msg.project, msg.status)
      failing = @getFailing()
      recentFailing = @getRecentFailing()

      if failing
        @writeMessages failing, 'failing to build'
      else if recentFailing
        @writeMessages recentFailing, 'recently failed to build'
      else
        @updateState(null)

    writeMessages: (msgs, doing) ->
      length = msgs.length
      tense = if doing == 'failing to build' then 'present' else 'past'

      joiner = (tense, num) ->
        if tense == 'present' and num == 1
          ' is '
        else if tense == 'present' and num > 1
          ' are '
        else
          ' '

      messages = (msgs, num) ->
        out = ''
        $.each msgs, (i, msg) ->
          if i == num - 2
            out += "#{msg} and "
          else if i == num - 1
            out += msg
          else
            out += "#{msg}, "
        return out

      txt = messages(msgs, length) + joiner(tense, length) + doing
      @updateState(txt)

    updateState: (txt) ->
      if @getFailing()
        @$body.addClass 'health-fail'
        @$body.removeClass 'health-recent-fail'
        @$failText.text txt
        @$body.css 'margin-top', @$failWrapper.outerHeight()
      else if @getRecentFailing()
        @$body.removeClass 'health-fail'
        @$body.addClass 'health-recent-fail'
        @$failText.text txt
        @$body.css 'margin-top', @$failWrapper.outerHeight()
      else
        @$body.removeClass 'health-recent-fail health-fail'
        @$failText.text ''
        @$body.css 'margin-top', 0

    getFailing: () ->
      result = []

      $.each _cache, (item) =>
        if @get(item) == 'FAILURE'
          result.push(item)

      if result.length > 0
        return result
      else
        return false

    getRecentFailing: () ->
      result = []

      $.each _cache, (item) =>
        if @get(item) == 'RECENT FAILURE'
          result.push(item)

      if result.length > 0
        return result
      else
        return false
  return Health
