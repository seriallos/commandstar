root = exports ? this
fs = require 'fs'
net = require 'net'
{EventEmitter} = require 'events'

{exec} = require 'child_process'

class ServerInfo extends EventEmitter

  STATUS_ERROR:   -2
  STATUS_UNKNOWN: -1
  STATUS_DOWN:     0
  STATUS_UP:       1
  STATUS_MULTIPLE: 2

  socketCheckMs:   5000

  defaultOpts:
    assetsPath: "/opt/starbound/assets"
    binPath: "/opt/starbound/bin"
    dataPath: "/opt/starbound/bin/universe"
    serverDaemonName: "starbound"

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

  init: ( next ) ->
    @__loadServerConfig ( err ) =>
      if err
        next( err )
      else
        @__startServerMonitor next

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
    @serverRunningIntervalId = setInterval( @__checkRunning, @socketCheckMs )
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

    socket.on 'error', ( error ) =>
      socket.destroy()
      console.log "Server status check FAILED"
      console.log error
      @setStatus @STATUS_DOWN

    socket.on 'connect', =>
      socket.destroy()
      @setStatus @STATUS_UP

root.ServerInfo = ServerInfo
