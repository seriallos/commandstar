{EventEmitter} = require 'events'
{Tail} = require 'tail'
fs = require 'fs'
readline = require 'readline'

class ServerLog extends EventEmitter

  LINE_CHAT_REGEX: /^Info:  <([^>]+)> (.*)/
  LINE_SERVER_START_REGEX: /^Info: Done loading Star::Root/
  LINE_SERVER_STOP_REGEX: /^Info: Server shutdown gracefully/

  # Info: UniverseServer: Client 'Spacefinger' <1> (209.6.253.90:56534) \
  # connected
  LINE_PLAYER_CONNECT_REGEX: ///
    ^Info:\sUniverseServer:\s
    Client\s'([^>]+)'\s<[^>]+>\s\(.*\)\sconnected
  ///

  # Info: UniverseServer: Reaping client 'Spacefinger' <1> \
  # (209.6.253.90:56534) connection
  LINE_PLAYER_DISCONNECT_REGEX: ///
    ^Info:\sUniverseServer:\s
    Reaping\sclient\s'([^']+)'\s<[^>]+>\s\(.*\)\sconnection
  ///

  # Info: UniverseServer: Loading world db for world \
  # alpha:-81190832:95778072:3036738:6:12
  LINE_WORLD_LOAD_REGEX: ///
    ^Info:\sUniverseServer:\sLoading\sworld\sdb\sfor\sworld\s+
    ([^:]+)         # sector
    :([^:]+)        # x
    :([^:]+)        # y
    :([^:]+)        # z
    :([^:\s]+)        # planet
    (:([^:\s]+))?   # satellite (not always present)
  ///

  # Info: UniverseServer: Shutting down world \
  # alpha:-81190832:95778072:3036738:6:12 due to inactivity
  LINE_WORLD_UNLOAD_REGEX: ///
    ^Info:\sUniverseServer:\sShutting\sdown\sworld\s+
    ([^:]+)         # sector
    :([^:]+)        # x
    :([^:]+)        # y
    :([^:]+)        # z
    :([^:\s]+)        # planet
    (:([^:\s]+))?   # satellite (not always present)
  ///

  # Info: Server version 'Beta v. Furious Koala' '635'
  LINE_SERVER_VERSION_REGEX: ///
    ^Info:\sServer\sversion\s'([^']+)'\s'([^']+)'
  ///

  LINE_SERVER_SEGFAULT: /^Error: Segfault Encountered!/

  logTail = null

  constructor: ( opts ) ->
    if not opts
      throw new Error "ServerLog requires options"
    if not opts.logFile
      throw new Error "ServerLog requires logFile in constructor options"

    @logFile = opts.logFile
    @watchInterval = opts.watchInterval ? 200
    @logTail = null

  init: ( next ) ->
    @processCurrentLog ( ) =>
      @logTail = null
      @startWatching next

  processCurrentLog: ( next ) ->
    rd = readline.createInterface({
      input: fs.createReadStream @logFile
      output: process.stdout
      terminal: false
    })
    rd.on 'line', (line) =>
      @onLogLine line, false
    rd.on 'close', ->
      next()

  startWatching: ( next ) ->
    @logTail = new Tail @logFile, "\n", { interval: @watchInterval }

    @logTail.on 'line', (line) =>
      @onLogLine line, true

    @logTail.on 'error', ( error ) =>
      console.log error

    next()

  stopWatching: ->
    @logTail.unwatch()

  onLogLine: ( data, fromActiveLog ) =>
    whn = new Date()
    if @isChatLine data
      [ who, what ] = @parseChatLine data
      @emit "chat", who, what, whn, fromActiveLog

    if @isServerStartLine data
      @emit "serverStart", whn, fromActiveLog

    if @isServerStopLine data
      @emit "serverStop", whn, fromActiveLog

    if @isPlayerConnectLine data
      playerId = @parsePlayerConnectLine data
      @emit "playerConnect", playerId, fromActiveLog

    if @isPlayerDisconnectLine data
      playerId = @parsePlayerDisconnectLine data
      @emit "playerDisconnect", playerId, fromActiveLog

    worldLoad = @parseWorldLoadLine data
    if worldLoad
      @emit "worldLoad", worldLoad, fromActiveLog

    worldUnload = @parseWorldUnloadLine data
    if worldUnload
      @emit "worldUnload", worldUnload, fromActiveLog

    version = @parseServerVersion data
    if version
      @emit "serverVersion", version, fromActiveLog

    if @isServerCrashLine data
      @emit 'serverCrash', data, whn, fromActiveLog

  isChatLine: ( line ) ->
    return line.match @LINE_CHAT_REGEX

  parseChatLine: ( line ) ->
    matches = line.match @LINE_CHAT_REGEX
    return [ matches[1], matches[2] ]

  isServerStartLine: ( line ) ->
    return line.match @LINE_SERVER_START_REGEX

  isServerStopLine: ( line ) ->
    return line.match @LINE_SERVER_STOP_REGEX

  isPlayerConnectLine: ( line ) ->
    return line.match @LINE_PLAYER_CONNECT_REGEX

  parsePlayerConnectLine: ( line ) ->
    matches = line.match @LINE_PLAYER_CONNECT_REGEX
    return matches[ 1 ]

  isPlayerDisconnectLine: ( line ) ->
    return line.match @LINE_PLAYER_DISCONNECT_REGEX

  parsePlayerDisconnectLine: ( line ) ->
    matches = line.match @LINE_PLAYER_DISCONNECT_REGEX
    return matches[ 1 ]

  parseWorldLoadLine: ( line ) ->
    matches = line.match @LINE_WORLD_LOAD_REGEX
    if matches
      ret =
        sector: matches[ 1 ]
        x: matches[ 2 ]
        y: matches[ 3 ]
        z: matches[ 4 ]
        planet: matches[ 5 ]
        satellite: matches[ 7 ]
      return ret
    else
      return false

  parseWorldUnloadLine: ( line ) ->
    matches = line.match @LINE_WORLD_UNLOAD_REGEX
    if matches
      ret =
        sector: matches[ 1 ]
        x: matches[ 2 ]
        y: matches[ 3 ]
        z: matches[ 4 ]
        planet: matches[ 5 ]
        satellite: matches[ 7 ]
      return ret
    else
      return false

  isServerCrashLine: ( data ) ->
    return data.match @LINE_SERVER_SEGFAULT

  parseServerVersion: ( line ) ->
    matches = line.match @LINE_SERVER_VERSION_REGEX
    if matches
      return matches[1]
    else
      return false

module.exports = ServerLog
