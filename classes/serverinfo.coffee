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

  socketCheckMs:   10000

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
        # TODO: Server bug makes monitoring eventually cause a crash
        #@__startServerMonitor next
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

    socket.on 'connect', =>
      socket.end()
      socket.destroy()
      @setStatus @STATUS_UP

    socket.on 'error', ( error ) =>
      socket.end()
      socket.destroy()
      @setStatus @STATUS_DOWN

root.ServerInfo = ServerInfo
