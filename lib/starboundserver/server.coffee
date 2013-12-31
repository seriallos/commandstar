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
  version: null
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
    serverChatName: 'SERVER'
    ignoreChatPrefixes: '/#'
    db: null

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
    @serverChatName = opts.serverChatName ? @defaultOpts.serverChatName
    @ignoreChatPrefixes =
      opts.ignoreChatPrefixes ? @defaultOpts.ignoreChatPrefixes
    @db = opts.db ? @defaultOpts.db

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
    monitor.on 'statusChange', @onMonitorStatusChange

  setupLogEvents: ( log ) ->
    log.on 'chat', @onLogChat
    log.on 'playerConnect', @onLogPlayerConnect
    log.on 'playerDisconnect', @onLogPlayerDisconnect
    log.on 'serverStart', @onLogServerStart
    log.on 'serverStop', @onLogServerStop
    log.on 'worldLoad', @onLogWorldLoad
    log.on 'worldUnload', @onLogWorldUnload
    log.on 'serverVersion', @onLogServerVersion
    log.on 'serverCrash', @onLogCrash

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

  isPublic: ->
    isPublic = false
    for password in @config.serverPasswords
      if '' == password
        isPublic = true
    return isPublic

  # --- State Management --- #

  clearPlayers: ->
    @players = []

  addPlayer: ( playerName ) ->
    @players.push playerName

  removePlayer: ( playerName ) ->
    idx = @players.indexOf playerName
    @players.splice idx, 1

  shouldIgnoreChat: ( message ) ->
    prefixIgnoreRegex = new RegExp '^['+@ignoreChatPrefixes+']'
    return message.match prefixIgnoreRegex

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

  addServerChat: ( what, whn, live ) ->
    @handleChat @serverChatName, what, whn, live

  # --- DB helpers --- #
  # TODO: Decompose this more nicely

  dbUpdatePlayer: ( playerId, change ) ->
    if @db
      q =
        name: playerId
      @db.players.update q, change, { upsert: true }, ( err, num, upsert ) =>
        if err
          console.log "Error updating db.players"
          console.log err

  dbUpdateWorld: ( world, change ) ->
    if @db
      q =
        sector: world.sector
        x: world.x
        y: world.y
        z: world.z
        planet: world.planet
        satellite: world.satellite ? null
      @db.worlds.update q, change, { upsert: true }, ( err, num, upsert ) ->
        if err
          console.log "Error updating world DB"
          console.log err


  # --- Event Emitting and Handilng --- #

  handleStart: ( whn, why, live ) ->
    @clearPlayers()
    @clearWorlds()
    if @status != ServerMonitor::STATUS_UP
      @status = ServerMonitor::STATUS_UP
      @addServerChat 'Started!', whn, live
      if live
        @emit 'start', whn, why

  handleStop: ( whn, why, live ) ->
    @clearPlayers()
    @clearWorlds()
    if @status != ServerMonitor::STATUS_DOWN
      @status = ServerMonitor::STATUS_DOWN
      @addServerChat 'Stopped!', whn, live
      if live
        @emit 'stop', whn, why

  handleChat: ( who, what, whn, live ) ->
    if not @shouldIgnoreChat what
      @addChat who, what, whn
      if live
        @emit 'chat', who, what, whn

  # --- Backend Event Management --- #

  onMonitorStatusChange: ( status ) =>
    if status == ServerMonitor::STATUS_UP
      @handleStart new Date(), 'monitor', true
    else
      @handleStop new Date(), 'monitor', true

  onLogChat: ( who, what, whn, live ) =>
    @handleChat who, what, whn, live

  onLogPlayerConnect: ( playerId, live ) =>
    @addPlayer playerId
    @addServerChat "#{playerId} joined the server.", new Date(), live
    if live
      @emit 'playerConnect', playerId
      change =
        $set:
          lastLogin: new Date()
        $inc:
          numLogins: 1
      @dbUpdatePlayer playerId, change

  onLogPlayerDisconnect: ( playerId, live ) =>
    @removePlayer playerId
    @addServerChat "#{playerId} left the server.", new Date(), live
    if live
      @emit 'playerDisconnect', playerId
      change =
        $set:
          lastLogout: new Date()
      @dbUpdatePlayer playerId, change

  onLogServerStart: ( whn, live ) =>
    @handleStart whn, 'log', live

  onLogServerStop: ( whn, live ) =>
    @handleStop whn, 'log', live

  onLogWorldLoad: ( world, live ) =>
    @updateWorld world, { active: true }
    if live
      @emit 'worldLoad', world
      change =
        $set:
          lastLoaded: new Date()
        $inc:
          numLoads: 1
      @dbUpdateWorld world, change

  onLogWorldUnload: ( world, live ) =>
    @updateWorld world, { active: false }
    if live
      @emit 'worldUnload', world
      change =
        $set:
          lastUnloaded: new Date()
      @dbUpdateWorld world, change

  onLogServerVersion: ( version, live ) =>
    @version = version
    @addServerChat "Server version is #{version}", new Date(), live
    if live
      @emit 'version', version

  onLogCrash: ( data, whn, live ) =>
    @handleStop whn, 'log crash', live

root.StarboundServer = StarboundServer
