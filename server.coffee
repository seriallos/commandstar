restify = require 'restify'
socketio = require 'socket.io'
fs = require 'fs'
config = require 'config'
_ = require 'underscore'

{ServerInfo} = require './classes/serverinfo.coffee'
{ServerLog} = require './classes/serverlog.coffee'
HipChat = require 'node-hipchat'

if config.hipchat?.token
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
  configPath: config.starbound.configFile
})

info.init ( err ) ->
  if err
    console.log err
    process.exit( 1 )

serverLog = new ServerLog( {
  logFile: config.starbound.logFile
} )

serverLog.init ( ) ->
  # nothing to do here

# TODO: wrap all this state tracking in ServerInfo or some other module
recentChat = []
playersOnline = []
gWorlds = []
serverVersion = null

pushRecentChat = ( message ) ->
  recentChat.push message

getActiveWorlds = ->
  worlds = _.where gWorlds, { active: true }
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
  t = _.sortBy( worlds, ( w ) -> sectorOrder[ w.sector ] )

serverLog.on "chat", ( who, what, chatWhen, fromActiveLog ) ->
  msg =
    who: who
    what: what
    when: chatWhen
  pushRecentChat msg
  if fromActiveLog
    io.sockets.emit 'chat', msg
    notifyHipchat "#{who}: #{what}"

info.on 'statusChange', ( status ) ->
  io.sockets.emit 'serverStatus', { status: status }
  # reset global state if server has gone down
  if status <= 0
    playersOnline = []
    activeWorlds = {}

serverLog.on "serverStart", ( chatWhen, fromActiveLog ) ->
  msg = { who: 'SERVER', what: 'Started!', when: chatWhen }
  pushRecentChat msg
  playersOnline = []
  activeWorlds = {}
  if fromActiveLog
    io.sockets.emit 'chat', msg
    io.sockets.emit 'serverStatus', { status: 1 }
    notifyHipchat "Server has started!"

serverLog.on "serverStop", ( chatWhen, fromActiveLog ) ->
  msg = { who: 'SERVER', what: 'Stopping!', when: chatWhen }
  pushRecentChat msg
  playersOnline = []
  activeWorlds = {}
  if fromActiveLog
    io.sockets.emit 'chat', msg
    io.sockets.emit 'serverStatus', { status: 0 }
    notifyHipchat "Server has stopped!"

serverLog.on "serverVersion", ( version, fromActiveLog ) ->
  serverVersion = version
  io.sockets.emit 'serverVersion', { version: serverVersion }

serverLog.on "playerConnect", ( playerId, fromActiveLog ) ->
  playersOnline.push playerId
  msg = { who: 'SERVER', what: playerId + ' joined the server.', when: new Date() }
  pushRecentChat msg
  if fromActiveLog
    io.sockets.emit 'playerCount', { playersOnline: playersOnline }
    io.sockets.emit 'chat', msg
    notifyHipchat "#{playerId} joined the server"

serverLog.on "playerDisconnect", ( playerId, fromActiveLog ) ->
  idx = playersOnline.indexOf playerId
  playersOnline.splice idx, 1
  msg = { who: 'SERVER', what: playerId + ' left the server.', when: new Date() }
  pushRecentChat msg
  if fromActiveLog
    io.sockets.emit 'playerCount', { playersOnline: playersOnline }
    io.sockets.emit 'chat', msg
    notifyHipchat "#{playerId} left the server"

serverLog.on "worldLoad", ( worldInfo, fromActiveLog ) ->

  world = _.findWhere gWorlds, worldInfo

  if not world
    world = _.clone worldInfo
    world.active = true
    gWorlds.push world
  else
    world.active = true

  if fromActiveLog
    data = { worlds: getActiveWorlds() }
    io.sockets.emit 'worlds', data

serverLog.on "worldUnload", ( worldInfo, fromActiveLog ) ->

  world = _.findWhere gWorlds, worldInfo

  if world
    # remove the world from the list
    gWorlds = _.without( gWorlds, world )
    # re-add with active false
    world.active = false
    gWorlds.push world

  if fromActiveLog
    data = { worlds: getActiveWorlds() }
    io.sockets.emit 'worlds', data

getServerStatus = ( req, res, next ) ->
  resData =
    serverName: config.serverName
    status: info.status
    gamePort: info.config.gamePort
    playersOnline: playersOnline
    activeWorlds: getActiveWorlds()
    version: serverVersion
  res.send resData
  return next()

getChat = ( req, res, next ) ->
  res.send recentChat
  return next()

server = restify.createServer()
server.use restify.CORS()

server.get /\/js\/?.*/, restify.serveStatic({
  directory: './public'
})
server.get /\/css\/?.*/, restify.serveStatic({
  directory: './public'
})
server.get /\/fonts\/?.*/, restify.serveStatic({
  directory: './public'
})

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

