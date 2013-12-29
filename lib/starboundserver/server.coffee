root = exports ? this
fs = require 'fs'
net = require 'net'
_ = require 'underscore'
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
    maxChatSize: 100

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
    @maxChatSize = opts.maxChatSize ? @defaultOpts.maxChatSize

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

  # --- Utility Access --- #

  activeWorlds: ->
    worlds = _.where @worlds, { active: true }
    # TODO: This limits to active SYSTEMS, not planets/satellites
    worlds = _.uniq worlds, ( item, key, list ) ->
      JSON.stringify( _.pick item, 'sector', 'x', 'y' )
    sectorOrder = {
      'alpha': 1
      'beta':  2
      'gamma': 3
      'delta': 4
      'sectorx': 5
    }
    return _.sortBy( worlds, ( w ) -> sectorOrder[ w.sector ] )

  # --- State Management --- #

  clearPlayers: ->
    @players = []

  addPlayer: ( playerName ) ->
    @players.push playerName

  removePlayer: ( playerName ) ->
    idx = @players.indexOf playerName
    @players.splice idx, 1

  addChat: ( who, what, whn ) ->
    msg =
      who: who
      what: what
      when: whn
    @chat.push msg
    if @chat.length > @maxChatSize
      @chat = @chat.slice -( @maxChatSize )

  clearWorlds: ->
    @worlds = []

  updateWorld: ( world, attrs ) ->
    w = _.findWhere @worlds, world

    if not w
      # not currently in the list.
      # prep the temp object for insertion
      w = _.clone world
    else
      # previously in the list.
      # Remove it from the list, it will be re-added with new attributes below
      @worlds = _.without( @worlds, w )

    # apply attributes, put back in the list.
    # note that i'm using defaults in sort of a "reverse" usage
    # attributes passed in are important, previous values are used if not
    # in the attributes
    w = _.defaults attrs, w
    @worlds.push w

  # --- Event Management --- #

  onStatusChange: ( status ) =>
    if @status != status
      @status = status
      if status <= 0
        @onServerStop( new Date(), true )
      else
        @onServerStart( new Date(), true )

  onChat: ( who, what, whn, live ) =>
    @addChat who, what, whn
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
    @updateWorld world, { active: true }
    if live
      @emit 'worldLoad', world

  onWorldUnload: ( world, live ) =>
    @updateWorld world, { active: false }
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
