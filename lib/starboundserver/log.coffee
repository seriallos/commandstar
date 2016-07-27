{EventEmitter} = require 'events'
{Tail} = require 'tail'
fs = require 'fs'
readline = require 'readline'

class ServerLog extends EventEmitter

  # [15:42:30.448] [Info] Chat: <Dave> test
  LINE_CHAT_REGEX: /\[Info\] Chat: <([^>]+)> (.*)/
  # [15:26:45.834] [Info] Root: Done preparing Root.
  LINE_SERVER_START_REGEX: /\[Info\] Root: Done preparing Root./
  # [15:47:44.043] [Info] Server shutdown gracefully
  LINE_SERVER_STOP_REGEX: /\[Info\] Server shutdown gracefully/

  # [15:28:47.523] [Info] UniverseServer: Client 'Dave' <1> (0000:0000:0000:0000:0000:0000:0000:0001) connected
  LINE_PLAYER_CONNECT_REGEX: ///
    \[Info\]\sUniverseServer:\s
    Client\s'([^>]+)'\s<[^>]+>\s\(.*\)\sconnected
  ///

  # [15:42:05.171] [Info] UniverseServer: Client 'Dave' <1> (0000:0000:0000:0000:0000:0000:0000:0001) disconnected for reason:.
  LINE_PLAYER_DISCONNECT_REGEX: ///
    \[Info\]\sUniverseServer:\s
    Client\s'([^>]+)'\s<[^>]+>\s\(.*\)\sdisconnected
  ///

  # [15:42:10.895] [Info] UniverseServer: Loading celestial world 319037651:786784446:-84230925:7:3
  LINE_WORLD_LOAD_REGEX: ///
    \[Info\]\sUniverseServer:\sLoading\scelestial\sworld
    ([^:]+)         # sector
    :([^:]+)        # x
    :([^:]+)        # y
    :([^:]+)        # z
    :([^:\s]+)      # planet
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
  # [15:26:49.875] [Info] Server Version 1.0.2 (macos x86_64) Source ID: 28d3ec461b83391b7b5cb981b031dbeee8437e56 Protocol: 723
  LINE_SERVER_VERSION_REGEX: ///
    \[Info\]\sServer\sVersion\s'([^']+)'\s'([^']+)'
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
