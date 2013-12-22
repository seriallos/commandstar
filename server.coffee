restify = require 'restify'
socketio = require 'socket.io'
fs = require 'fs'
config = require 'config'
_ = require 'underscore'

{ServerInfo} = require './classes/serverinfo.coffee'
{ServerLog} = require './classes/serverlog.coffee'
HipChat = require 'node-hipchat'
irc = require 'irc'

if config.hipchat?.token
  hipchat = new HipChat config.hipchat.token
  console.log "HipChat integration enabled"

if config.irc
  ircClient = new irc.Client(
    config.irc.server,
    config.irc.nick,
    {
      userName: config.irc.user
      password: config.irc.password
    }
  )
  ircClient.addListener 'error', (message) ->
    console.log "IRC Relay Error"
    console.log message
  ircClient.addListener 'registered', (message) ->
    console.log "Connected to IRC #{config.irc.server}:#{config.irc.channel}"
    ircClient.join config.irc.channel


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

notifyIrc = ( msg ) ->
  if ircClient
    ircClient.say config.irc.channel, msg

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
  # keep last N messages if recent chat is too big
  if recentChat.length > config.maxRecentChatMessages
    recentChat = recentChat.slice -(config.maxRecentChatMessages)

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

isSlashCommand = ( message ) ->
  message[0] == '/'

serverLog.on "chat", ( who, what, chatWhen, fromActiveLog ) ->
  msg =
    who: who
    what: what
    when: chatWhen
  # ignore slash commands
  if not isSlashCommand what
    pushRecentChat msg
    if fromActiveLog
      io.sockets.emit 'chat', msg
      notifyHipchat "#{who}: #{what}"
      notifyIrc "#{who}: #{what}"

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
    notifyIrc "Server has started!"

serverLog.on "serverStop", ( chatWhen, fromActiveLog ) ->
  msg = { who: 'SERVER', what: 'Stopping!', when: chatWhen }
  pushRecentChat msg
  playersOnline = []
  activeWorlds = {}
  if fromActiveLog
    io.sockets.emit 'chat', msg
    io.sockets.emit 'serverStatus', { status: 0 }
    notifyHipchat "Server has stopped!"
    notifyIrc "Server has stopped!"

serverLog.on "serverVersion", ( version, fromActiveLog ) ->
  serverVersion = version
  io.sockets.emit 'serverVersion', { version: serverVersion }

serverLog.on "playerConnect", ( playerId, fromActiveLog ) ->
  playersOnline.push playerId
  txt = playerId + ' joined the server.'
  msg = { who: 'SERVER', what: txt, when: new Date() }
  pushRecentChat msg
  if fromActiveLog
    io.sockets.emit 'playerCount', { playersOnline: playersOnline }
    io.sockets.emit 'chat', msg
    notifyHipchat "#{playerId} joined the server"
    notifyIrc "#{playerId} joined the server"

serverLog.on "playerDisconnect", ( playerId, fromActiveLog ) ->
  idx = playersOnline.indexOf playerId
  playersOnline.splice idx, 1
  txt = playerId + ' left the server.'
  msg = { who: 'SERVER', what: txt, when: new Date() }
  pushRecentChat msg
  if fromActiveLog
    io.sockets.emit 'playerCount', { playersOnline: playersOnline }
    io.sockets.emit 'chat', msg
    notifyHipchat "#{playerId} left the server"
    notifyIrc "#{playerId} left the server"

serverLog.on "worldLoad", ( worldInfo, fromActiveLog ) ->
  # gate all system functionality on a feature flag
  if config.features.activeSystems
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
  # gate all system functionality on a feature flag
  if config.features.activeSystems
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

serverLog.on "serverCrashAtStart", ( chatWhen, fromActiveLog ) ->
  msg = { who: 'SERVER', what: 'Server has stopped (crash on start)!', when: chatWhen }
  pushRecentChat msg
  playersOnline = []
  activeWorlds = {}
  if fromActiveLog
    io.sockets.emit 'chat', msg
    io.sockets.emit 'serverStatus', { status: 0 }
    notifyHipchat "Server has stopped (crash on start)!"
    notifyIrc "Server has stopped (crash on start)!"

getServerStatus = ( req, res, next ) ->
  isPublic = false
  for password in info.config.serverPasswords
    if '' == password
      isPublic = true
  resData =
    serverName: config.serverName
    serverDesc: config.serverDescription
    status: info.status
    gamePort: info.config.gamePort
    playersOnline: playersOnline
    activeWorlds: getActiveWorlds()
    version: serverVersion
    maxPlayers: info.config.maxPlayers ? 8 # guess at default?
    public: isPublic
    css: config.customCss
    features: config.features
  res.send resData
  return next()

# Used by starbound-servers.net.  Don't change data output without confirming
# change with malobre
getPlayerList = (req, res, next) ->
  plist = []
  for i of playersOnline
    plist.push(nickname: playersOnline[i])
  resData =
    playercount: playersOnline.length
    playerlist: plist
  res.send resData
  next()

getChat = ( req, res, next ) ->
  res.send recentChat
  return next()

server = restify.createServer()
server.name = "CommandStar"
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
server.get( '/server/playerList', getPlayerList )
server.get( '/server/players', getPlayerList )

ioOpts =
  'log level': 1

io = socketio.listen server, ioOpts

server.listen config.listenPort, ->
  console.log "%s listening on port %s", server.name, server.url
