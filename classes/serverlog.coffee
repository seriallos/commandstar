root = exports ? this

{EventEmitter} = require 'events'
{Tail} = require 'tail'
fs = require 'fs'
readline = require 'readline'

class ServerLog extends EventEmitter

  LINE_CHAT_REGEX: /^Info:  <([^>]+)> (.*)$/
  LINE_SERVER_START_REGEX: /^Info: Done loading Star::Root/
  LINE_SERVER_STOP_REGEX: /^Info: Server shut down gracefully/
  LINE_PLAYER_CONNECT_REGEX: /^Info: Client <([^>]+)> connected/
  LINE_PLAYER_DISCONNECT_REGEX: /^Info: Client <([^>]+)> disconnected/

  constructor: ( opts ) ->
    if not opts
      opts = {}
    @logFile = opts.logFile

    @processCurrentLog()

    @logTail = null
    @startWatching()

  processCurrentLog: ->
    console.log "Reading the entire log to get current state"
    rd = readline.createInterface({
      input: fs.createReadStream @logFile
      output: process.stdout
      terminal: false
    })
    rd.on 'line', @onLogLine

  startWatching: ->
    @logTail = new Tail @logFile

    @logTail.on 'line', @onLogLine

  stopWatching: ->
    @logTail.unwatch()
    @logTail = null

  onLogLine: ( data ) =>
    whn = new Date()
    if @isChatLine data
      [ who, what ] = @parseChatLine data
      @emit "chat", who, what, whn
    if @isServerStartLine data
      @emit "serverStart", whn
    if @isServerStopLine data
      @emit "serverStop", whn
    if @isPlayerConnectLine data
      playerId = @parsePlayerConnectLine data
      @emit "playerConnect", playerId
    if @isPlayerDisconnectLine data
      playerId = @parsePlayerDisconnectLine data
      @emit "playerDisconnect", playerId

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
    return parseInt matches[ 1 ]

  isPlayerDisconnectLine: ( line ) ->
    return line.match @LINE_PLAYER_DISCONNECT_REGEX

  parsePlayerDisconnectLine: ( line ) ->
    matches = line.match @LINE_PLAYER_DISCONNECT_REGEX
    return parseInt matches[ 1 ]


root.ServerLog = ServerLog
