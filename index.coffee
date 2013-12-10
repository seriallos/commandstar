restify = require 'restify'
socketio = require 'socket.io'
fs = require 'fs'

{ServerInfo} = require './classes/serverinfo.coffee'
{ServerLog} = require './classes/serverlog.coffee'

info = new ServerInfo()
serverLog = new ServerLog( { logFile: "#{info.binPath}/starbound_server.log" } )

# TODO: wrap all this state tracking in ServerInfo or some other module
recentChat = []
playersOnline = []

serverLog.on "chat", ( who, what, chatWhen ) ->
  msg =
    who: who
    what: what
    when: chatWhen
  recentChat.push msg
  io.sockets.emit 'chat', msg

serverLog.on "serverStart", ( chatWhen ) ->
  recentChat.push { who: 'SERVER', what: 'Started!', when: chatWhen }

serverLog.on "serverStop", ( chatWhen ) ->
  recentChat.push { who: 'SERVER', what: 'Stopping!', when: chatWhen }

serverLog.on "playerConnect", ( playerId ) ->
  playersOnline.push playerId
  io.sockets.emit 'playerCount', { num: playersOnline.length }

serverLog.on "playerDisconnect", ( playerId ) ->
  idx = playersOnline.indexOf playerId
  playersOnline.splice idx, 1
  io.sockets.emit 'playerCount', { num: playersOnline.length }

getServerStatus = ( req, res, next ) ->
  resData =
    status: info.status
    gamePort: info.config.gamePort
    playersOnline: playersOnline.length
  res.send resData
  return next()

getChat = ( req, res, next ) ->
  res.send recentChat
  return next()

server = restify.createServer()
server.use restify.CORS()

server.get( '/server/status', getServerStatus )
server.get( '/server/chat', getChat )

io = socketio.listen server

io.sockets.on "connection", ( socket ) ->
  console.log "socket connection"

server.listen 9090, ->
  console.log "%s listening on port %s", server.name, server.url

