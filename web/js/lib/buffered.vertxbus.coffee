class BufferedEventBus extends vertx.EventBus
  constructor:(url, options)->
    @sendBuffer = []
    @publishBuffer = []
    onopen = options?.onopen
    onclose = options?.onclose
    @connected = false
    options ?= {}
    options.onopen = =>
      @connected = true
      onopen?()
      if @sendBuffer
        for v in @sendBuffer
          @send v...
      if @publishBuffer
        for v in @publishBuffer
          @send v...
    options.onclose = =>
      @connected = false
      onclose?()
    super url,options
  send:(address, message, replyHandler)->
    if not @connected
      @sendBuffer.push(arguments)
    else
      super arguments...
  publish:(address, message, replyHandler)->
    if not @connected
      @publishBuffer.push(arguments)
    else
      super arguments...
