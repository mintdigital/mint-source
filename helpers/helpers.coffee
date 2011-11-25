fs = require('fs')

exports.discretify = (name, substitutes) ->
  discreteName = name
  if substitutes
    for sub of substitutes
      if substitutes[sub].orig == name
        discreteName = substitutes[sub].subs
        return discreteName

  return discreteName

exports.compile = (resource, callback) ->
  # Takes a CoffeeScript resource name and runs a callback with compiled
  # JavaScript as the first argument
  filePath = "./public/javascripts/#{resource}.coffee"
  fs.readFile filePath, 'utf-8', (err, data) ->
    compiled = coffee.compile(data)
    callback(compiled)

