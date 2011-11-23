exports.discretify = (name, substitutes) ->
  discreteName = name
  if substitutes
    for sub of substitutes
      if substitutes[sub].orig == name
        discreteName = substitutes[sub].subs
        return discreteName

  return discreteName