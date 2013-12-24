root = exports ? this
fs = require 'fs'
net = require 'net'
{EventEmitter} = require 'events'

{ServerMonitor} = require './monitor.coffee'

class StarboundServer extends EventEmitter

  defaultOpts:
    assetsPath: "/opt/starbound/assets"
    binPath: "/opt/starbound/bin"
    dataPath: "/opt/starbound/bin/universe"
    checkStatus: false
    checkFrequency: 60

  constructor: ( opts ) ->

    if not opts
      opts = {}

    @config = {}
    @status = @STATUS_UNKNOWN
    @serverRunningIntervalId = null

    @assetsPath = opts.assetsPath ? @defaultOpts.assetsPath
    @binPath = opts.binPath ? @defaultOpts.binPath
    @dataPath = opts.dataPath ? @defaultOpts.dataPath
    @configPath = opts.configPath ? @defaultOpts.binPath + "/starbound.config"
    @checkStatus = opts.checkStatus ? @defaultOpts.checkStatus
    # convert seconds to milliseconds
    @checkFrequency = opts.checkFrequency ? @defaultOpts.checkFrequency

    #if @checkFrequency < 1
    #  throw new Error "checkFrequency cannot be lower than 1 second."

  init: ( next ) ->
    @__loadServerConfig ( err ) =>
      if err
        next( err )
      else
        if @checkStatus
          console.log "Starting server monitor"
          @__startServerMonitor next
        else
          next()

  __loadServerConfig: ( next ) ->
    configFile = @configPath
    fs.readFile configFile, 'utf8', ( err, data ) =>
      if err
        error =
          message: "Unable to read config file: #{err}"
          cause: err
        next( error )
      else
        @config = JSON.parse data
        next( null )

  #### Server Process Monitoring

  __startServerMonitor: ( next ) ->
    timeoutMs = @checkFrequency * 1000
    # call once immediately
    @__checkRunning()
    # schedule recurring call based on the timeout
    @serverRunningIntervalId = setInterval( @__checkRunning, timeoutMs )
    next()

  __stopServerMonitor: ->
    clearInterval @serverRunningIntervalId

  setStatus: ( status ) ->
    if @status != status
      @emit 'statusChange', status
    @status = status

  # fat arrow to avoid the interval context
  __checkRunning: =>
    # fat arrow so class context is maintained in callback
    # maybe hacky
    socket = net.createConnection @config.gamePort, 'localhost'

    socket.on 'connect', =>
      socket.end()
      socket.destroy()
      @setStatus @STATUS_UP

    socket.on 'error', ( error ) =>
      socket.end()
      socket.destroy()
      @setStatus @STATUS_DOWN

root.StarboundServer = StarboundServer
