root = exports ? this
fs = require 'fs'
net = require 'net'
{EventEmitter} = require 'events'

{ServerMonitor} = require './monitor.coffee'

class StarboundServer extends EventEmitter

  monitor: null

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

    @assetsPath = opts.assetsPath ? @defaultOpts.assetsPath
    @binPath = opts.binPath ? @defaultOpts.binPath
    @dataPath = opts.dataPath ? @defaultOpts.dataPath
    @configPath = opts.configPath ? @defaultOpts.binPath + "/starbound.config"
    @checkStatus = opts.checkStatus ? @defaultOpts.checkStatus
    # convert seconds to milliseconds
    @checkFrequency = opts.checkFrequency ? @defaultOpts.checkFrequency

  init: ( next ) ->
    @loadServerConfig ( err ) =>
      if err
        next( err )
      else
        @loadServerMonitor ->
          next()

  reset: ->
    # make sure to clear out the monitor and stop watching
    if @monitor
      @monitor.unwatch()
      @monitor = null

  loadServerConfig: ( next ) ->
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

  loadServerMonitor: ( next ) ->
    monitorOpts =
      gamePort: @config.gamePort
      gameHost: 'localhost'
      checkFrequency: @checkFrequency
    @monitor = new ServerMonitor monitorOpts
    @setupMonitorEvents @monitor
    if @checkStatus
      @monitor.watch ->
        next()
    else
      next()

  setupMonitorEvents: ( monitor ) ->
    monitor.on 'statusChange', ( status ) =>
      @emit 'statusChange', status

root.StarboundServer = StarboundServer
