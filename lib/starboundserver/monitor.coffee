net = require 'net'
_ = require 'lodash'
{EventEmitter} = require 'events'

class ServerMonitor extends EventEmitter

  STATUS_ERROR:   -2
  STATUS_UNKNOWN: -1
  STATUS_DOWN:     0
  STATUS_UP:       1
  STATUS_MULTIPLE: 2

  status: null
  watchIntervalId: null

  defaultOpts:
    gameHost: 'localhost'
    gamePort: 21025
    checkFrequency: 300

  constructor: ( opts = {} ) ->
    opts = _.defaults opts, @defaultOpts

    for key, val of opts
      @[key] = val

  setStatus: ( status ) ->
    if @status != status
      @emit 'statusChange', status
    @status = status

  check: ( next = null) =>
    socket = net.createConnection @gamePort, @gameHost

    socket.on 'connect', =>
      socket.end()
      socket.destroy()
      # possible that class is destroyed before socket finishes
      # this guards against that possibility
      if this?.setStatus?
        @setStatus @STATUS_UP
        if next
          next null, @STATUS_UP

    socket.on 'error', ( error ) =>
      socket.end()
      socket.destroy()
      # possible that class is destroyed before socket finishes
      # this guards against that possibility
      if this?.setStatus?
        @setStatus @STATUS_DOWN
        if next
          next error, @STATUS_DOWN

  watch: ( next = null ) ->
    timeoutMs = @checkFrequency * 1000
    # call once immediately
    @check =>
      # schedule recurring call based on the timeout
      @watchIntervalId = setInterval( @check, timeoutMs )
      if next
        next()

  unwatch: ->
    clearInterval @watchIntervalId
    @watchIntervalId = null

module.exports = ServerMonitor
