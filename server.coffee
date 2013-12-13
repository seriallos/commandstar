restify = require 'restify'
socketio = require 'socket.io'
fs = require 'fs'
config = require 'config'

{ServerInfo} = require './classes/serverinfo.coffee'
{ServerLog} = require './classes/serverlog.coffee'
HipChat = require 'node-hipchat'

if config.hipchat?.token
  console.log "Hipchat configuration detected, loading hipchat code"
  hipchat = new HipChat config.hipchat.token

# TODO: Pull this into a module or something
notifyHipchat = ( msg ) ->
  if hipchat
    options =
      message: msg
      room: config.hipchat.room
      from: config.hipchat.user
      notify: config.hipchat.notify
      color: config.hipchat.color

    hipchat.postMessage options, ( response, error ) ->
      if error
        console.log "Hipchat notification error: #{error}"

info = new ServerInfo({
  binPath: config.starbound.binPath
  assetsPath: config.starbound.assetsPath
  dataPath: config.starbound.dataPath
})

serverLog = new ServerLog( {
  logFile: config.starbound.logFile
} )

# TODO: wrap all this state tracking in ServerInfo or some other module
recentChat = []
playersOnline = []
visitedWorlds = {}
activeWorlds = {}

serverLog.on "chat", ( who, what, chatWhen, fromActiveLog ) ->
  msg =
    who: who
    what: what
    when: chatWhen
  recentChat.push msg
  if fromActiveLog
    io.sockets.emit 'chat', msg
    notifyHipchat "GAME - #{who}: #{what}"

serverLog.on "serverStart", ( chatWhen, fromActiveLog ) ->
  msg = { who: 'SERVER', what: 'Started!', when: chatWhen }
  recentChat.push msg
  if fromActiveLog
    io.sockets.emit 'chat', msg
    notifyHipchat "Server has started!"

serverLog.on "serverStop", ( chatWhen, fromActiveLog ) ->
  msg = { who: 'SERVER', what: 'Stopping!', when: chatWhen }
  recentChat.push msg
  if fromActiveLog
    io.sockets.emit 'chat', msg
    notifyHipchat "Server has stopped!"

serverLog.on "playerConnect", ( playerId, fromActiveLog ) ->
  playersOnline.push playerId
  if fromActiveLog
    io.sockets.emit 'playerCount', { playersOnline: playersOnline }
    notifyHipchat "#{playerId} joined the server"

serverLog.on "playerDisconnect", ( playerId, fromActiveLog ) ->
  idx = playersOnline.indexOf playerId
  playersOnline.splice idx, 1
  if fromActiveLog
    io.sockets.emit 'playerCount', { playersOnline: playersOnline }
    notifyHipchat "#{playerId} left the server"

serverLog.on "worldLoad", ( worldInfo, fromActiveLog ) ->
  sector = worldInfo.sector
  systemX = worldInfo.x
  systemY = worldInfo.y
  group = worldInfo.group
  planet = worldInfo.planet

  # TODO: This is terrible.  Wrap this in something reasonable
  if not visitedWorlds[sector]
    visitedWorlds[sector] = {}
  if not visitedWorlds[sector][systemX]
    visitedWorlds[sector][systemX] = {}
  if not visitedWorlds[sector][systemX][systemY]
    visitedWorlds[sector][systemX][systemY] = {}
  if not visitedWorlds[sector][systemX][systemY][group]
    visitedWorlds[sector][systemX][systemY][group] = {}
  visitedWorlds[ sector ][ systemX ][ systemY ][ group ][ planet ] = true

  # TODO: This is terrible.  Wrap this in something reasonable
  if not activeWorlds[sector]
    activeWorlds[sector] = {}
  if not activeWorlds[sector][systemX]
    activeWorlds[sector][systemX] = {}
  if not activeWorlds[sector][systemX][systemY]
    activeWorlds[sector][systemX][systemY] = {}
  if not activeWorlds[sector][systemX][systemY][group]
    activeWorlds[sector][systemX][systemY][group] = {}
  activeWorlds[ sector ][ systemX ][ systemY ][ group ][ planet ] = true

serverLog.on "worldUnload", ( worldInfo, fromActiveLog ) ->
  sector = worldInfo.sector
  systemX = worldInfo.x
  systemY = worldInfo.y
  group = worldInfo.group
  planet = worldInfo.planet

  # TODO: This is terrible.  Wrap this in something reasonable
  if not activeWorlds[sector]
    activeWorlds[sector] = {}
  if not activeWorlds[sector][systemX]
    activeWorlds[sector][systemX] = {}
  if not activeWorlds[sector][systemX][systemY]
    activeWorlds[sector][systemX][systemY] = {}
  if not activeWorlds[sector][systemX][systemY][group]
    activeWorlds[sector][systemX][systemY][group] = {}
  activeWorlds[ sector ][ systemX ][ systemY ][ group ][ planet ] = false

getServerStatus = ( req, res, next ) ->
  resData =
    status: info.status
    gamePort: info.config.gamePort
    playersOnline: playersOnline
    activeWorlds: activeWorlds
  res.send resData
  return next()

getChat = ( req, res, next ) ->
  res.send recentChat
  return next()

server = restify.createServer()
server.use restify.CORS()

server.get '/', ( req, res, next ) ->
  fs.readFile __dirname + '/public/index.html', (err, data ) ->
    if err
      next err
      return
    res.setHeader 'Content-Type', 'text/html'
    res.writeHead 200
    res.end data
    next()

server.get( '/server/status', getServerStatus )
server.get( '/server/chat', getChat )

ioOpts =
  'log level': 2

io = socketio.listen server, ioOpts

server.listen config.listenPort, ->
  console.log "%s listening on port %s", server.name, server.url

