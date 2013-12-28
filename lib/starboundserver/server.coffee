root = exports ? this
fs = require 'fs'
net = require 'net'
{EventEmitter} = require 'events'

{ServerMonitor} = require './monitor.coffee'
{ServerLog} = require './log.coffee'

class StarboundServer extends EventEmitter

  monitor: null
  log: null

  status: null
  players: []
  worlds: []
  chat: []

  defaultOpts:
    assetsPath: "/opt/starbound/assets"
    binPath: "/opt/starbound/bin"
    dataPath: "/opt/starbound/bin/universe"
    logFile: "/opt/starbound/bin/starbound_server.log"
    checkStatus: false
    checkFrequency: 60
    watchInterval: 100

  constructor: ( opts ) ->

    if not opts
      opts = {}

    @config = {}

    @assetsPath = opts.assetsPath ? @defaultOpts.assetsPath
    @binPath = opts.binPath ? @defaultOpts.binPath
    @dataPath = opts.dataPath ? @defaultOpts.dataPath
    @configPath = opts.configPath ? @defaultOpts.binPath + "/starbound.config"
    @logFile = opts.logFile ? @defaultOpts.logFile
    @checkStatus = opts.checkStatus ? @defaultOpts.checkStatus
    # convert seconds to milliseconds
    @checkFrequency = opts.checkFrequency ? @defaultOpts.checkFrequency
    @watchInterval = opts.watchInterval ? @defaultOpts.watchInterval

    @players = []
    @worlds = []
    @chat = []
    @status = null
    @monitor = null
    @log = null

  init: ( next ) ->
    @loadServerConfig ( err ) =>
      if err
        next( err )
      else
        @loadServerMonitor =>
          @loadServerLog =>
            next()

  reset: ->
    # make sure to clear out the monitor and stop watching
    if @monitor
      @monitor.unwatch()
      @monitor = null
    if @log
      @log.stopWatching()
      @log = null

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

  loadServerLog: ( next ) ->
    logOpts =
      logFile: @logFile
      watchInterval: @watchInterval

    @log = new ServerLog logOpts
    @setupLogEvents @log
    @log.init ->
      next()

  setupMonitorEvents: ( monitor ) ->
    monitor.on 'statusChange', @onStatusChange

  setupLogEvents: ( log ) ->
    log.on 'chat', @onChat
    log.on 'playerConnect', @onPlayerConnect
    log.on 'playerDisconnect', @onPlayerDisconnect
    log.on 'serverStart', @onServerStart
    log.on 'serverStop', @onServerStop
    log.on 'worldLoad', @onWorldLoad
    log.on 'worldUnload', @onWorldUnload
    log.on 'serverVersion', @onServerVersion
    log.on 'serverCrash', @onCrash

  # --- State Management --- #

  clearPlayers: ->
    @players = []

  addPlayer: ( playerName ) ->
    @players.push playerName

  removePlayer: ( playerName ) ->
    idx = @players.indexOf playerName
    @players.splice idx, 1

  clearWorlds: ->
    @worlds = []

  # --- Event Management --- #

  onStatusChange: ( status ) =>
    if @status != status
      @status = status
      if status <= 0
        @onServerStop( new Date(), true )
      else
        @onServerStart( new Date(), true )

  onChat: ( who, what, whn, live ) =>
    if live
      @emit 'chat', who, what, whn

  onPlayerConnect: ( playerId, live ) =>
    @addPlayer playerId
    if live
      @emit 'playerConnect', playerId

  onPlayerDisconnect: ( playerId, live ) =>
    @removePlayer playerId
    if live
      @emit 'playerDisconnect', playerId

  onServerStart: ( whn, live ) =>
    @clearPlayers()
    @clearWorlds()
    if live
      @status = ServerMonitor::STATUS_UP
      @emit 'start', whn

  onServerStop: ( whn, live ) =>
    @clearPlayers()
    @clearWorlds()
    if live
      @status = ServerMonitor::STATUS_DOWN
      @emit 'stop', whn

  onWorldLoad: ( world, live ) =>
    if live
      @emit 'worldLoad', world

  onWorldUnload: ( world, live ) =>
    if live
      @emit 'worldUnload', world

  onServerVersion: ( version, live ) =>
    if live
      @emit 'version', version

  onCrash: ( data, whn, live ) =>
    @clearPlayers()
    @clearWorlds()
    if live
      @emit 'crash', data, whn

root.StarboundServer = StarboundServer
