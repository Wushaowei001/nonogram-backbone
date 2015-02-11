Storage.prototype.setObject = (key, value) ->
  @setItem key, JSON.stringify(value)

Storage.prototype.getObject = (key) ->
  value = @getItem(key)
  return value and JSON.parse(value)

Storage.prototype.getBoolean = (key) ->
  @getItem(key) is 'true'
