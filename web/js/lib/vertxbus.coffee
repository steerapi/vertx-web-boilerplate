vertx = vertx or {}
class vertx.EventBus
  CONNECTING = 0
  OPEN = 1
  CLOSING = 2
  CLOSED = 3
  constructor:(@url, @options) ->
    @sockJSConn = null
    @handlerMap = {}
    @replyHandlers = {}
    @state = vertx.EventBus.CONNECTING
    @onopen = (if options then options.onopen else null)
    @onclose = (if options then options.onclose else null)
 
  sendOrPub: (sendOrPub, address, message, replyHandler) ->
    @checkSpecified "address", "string", address
    @checkSpecified "message", "object", message
    @checkSpecified "replyHandler", "function", replyHandler, true
    @checkOpen()
    envelope =
      type: sendOrPub
      address: address
      body: message

    if replyHandler
      replyAddress = @makeUUID()
      envelope.replyAddress = replyAddress
      @replyHandlers[replyAddress] = replyHandler
    json = angular.toJson || JSON.stringify
    str = json(envelope)
    @sockJSConn.send str
  checkOpen: ->
    throw new Error("INVALID_STATE_ERR")  unless @state is vertx.EventBus.OPEN
  checkSpecified: -> (paramName, paramType, param, optional) ->
    throw new Error("Parameter " + paramName + " must be specified")  if not optional and not param
    throw new Error("Parameter " + paramName + " must be of type " + paramType)  if param and typeof param isnt paramType
  isFunction: (obj) ->
    !!(obj and obj.constructor and obj.call and obj.apply)
  makeUUID: ->
    "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (a, b) ->
      b = Math.random() * 16
      (if a is "y" then b & 3 | 8 else b | 0).toString(16)
  open : ->
    @sockJSConn = new SockJS(@url, @options)
    @sockJSConn.onopen = =>
      @state = vertx.EventBus.OPEN
      @onopen()  if @onopen

    @sockJSConn.onclose = =>
      @state = vertx.EventBus.CLOSED
      @onclose()  if @onclose

    @sockJSConn.onmessage = (e) =>
      msg = e.data
      json = JSON.parse(msg)
      body = json.body
      # console.log msg
      # console.log JSON.stringify(json)
      replyAddress = json.replyAddress
      address = json.address
      replyHandler = undefined
      if replyAddress
        replyHandler = (reply, replyHandler) ->
          send replyAddress, reply, replyHandler
      handlers = @handlerMap[address]
      if handlers
        copy = handlers.slice(0)
        i = 0

        while i < copy.length
          copy[i] body, replyHandler
          i++
      else
        handler = @replyHandlers[address]
        if handler
          delete @replyHandlers[address]
          
          handler body, replyHandler

  send : (address, message, replyHandler) ->
    @sendOrPub "send", address, message, replyHandler

  publish : (address, message, replyHandler) ->
    @sendOrPub "publish", address, message, replyHandler

  registerHandler : (address, handler) ->
    @checkSpecified "address", "string", address
    @checkSpecified "handler", "function", handler
    @checkOpen()
    handlers = @handlerMap[address]
    unless handlers
      handlers = [ handler ]
      @handlerMap[address] = handlers
      msg =
        type: "register"
        address: address

      @sockJSConn.send JSON.stringify(msg)
    else
      handlers[handlers.length] = handler

  unregisterHandler : (address, handler) ->
    @checkSpecified "address", "string", address
    @checkSpecified "handler", "function", handler
    @checkOpen()
    handlers = @handlerMap[address]
    if handlers
      idx = handlers.indexOf(handler)
      handlers.splice idx, 1  unless idx is -1
      if handlers.length is 0
        msg =
          type: "unregister"
          address: address

        @sockJSConn.send JSON.stringify(msg)
        delete @handlerMap[address]

  close : ->
    @checkOpen()
    @state = vertx.EventBus.CLOSING
    @sockJSConn.close()
    @sockJSConn = null

  readyState : ->
    @state

