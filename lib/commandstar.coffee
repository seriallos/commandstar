restify = require 'restify'
socketio = require 'socket.io'
fs = require 'fs'
config = require 'config'
_ = require 'lodash'
Datastore = require 'nedb'

StarboundServer = require './starboundserver/server.coffee'
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

db = {}

dbOpts =
  players:
    filename: config.datastore.dataPath + "/players.db"
    autoload: true
  worlds:
    filename: config.datastore.dataPath + "/worlds.db"
    autoload: true

for dbName, dbConfig of dbOpts
  db[ dbName ] = new Datastore dbConfig

starserver = new StarboundServer({
  binPath: config.starbound.binPath
  assetsPath: config.starbound.assetsPath
  dataPath: config.starbound.dataPath
  configPath: config.starbound.configFile
  logFile: config.starbound.logFile
  checkStatus: config.features.serverStatus
  checkFrequency: config.serverStatus.checkFrequency
  maxChatSize: config.maxRecentChatMessages
  ignoreChatPrefixes: config.ignoreChatPrefixes
  db: db
})

starserver.init ( err ) ->
  if err
    console.log err
    process.exit( 1 )

starserver.on "chat", ( who, what, chatWhen ) ->
  msg =
    who: who
    what: what
    when: chatWhen
  io.sockets.emit 'chat', msg
  notifyHipchat "#{who}: #{what}"
  notifyIrc "#{who}: #{what}"

starserver.on "start", ( chatWhen, why ) ->
  io.sockets.emit 'serverStatus', { status: 1 }
  io.sockets.emit 'playerCount', { playersOnline: starserver.players }
  data = { worlds: starserver.activeWorlds() }
  io.sockets.emit 'worlds', data

starserver.on "stop", ( chatWhen, why ) ->
  io.sockets.emit 'serverStatus', { status: 0 }
  io.sockets.emit 'playerCount', { playersOnline: starserver.players }
  data = { worlds: starserver.activeWorlds() }
  io.sockets.emit 'worlds', data

starserver.on "version", ( version ) ->
  io.sockets.emit 'serverVersion', { version: starserver.version }

starserver.on "playerConnect", ( playerId ) ->
  io.sockets.emit 'playerCount', { playersOnline: starserver.players }

starserver.on "playerDisconnect", ( playerId ) ->
  io.sockets.emit 'playerCount', { playersOnline: starserver.players }

starserver.on "worldLoad", ( worldInfo ) ->
  # gate all system functionality on a feature flag
  if config.features.activeSystems
    data = { worlds: starserver.activeWorlds() }
    io.sockets.emit 'worlds', data

starserver.on "worldUnload", ( worldInfo ) ->
  # gate all system functionality on a feature flag
  if config.features.activeSystems
    data = { worlds: starserver.activeWorlds() }
    io.sockets.emit 'worlds', data

getServerStatus = ( req, res, next ) ->
  # get world count
  starserver.allWorldsCount ( worldCount ) ->
    starserver.allPlayersCount ( playerCount ) ->
      resData =
        serverName: config.serverName
        serverDesc: config.serverDescription
        status: starserver.status
        gamePort: starserver.config.gamePort
        playersOnline: starserver.players
        activeWorlds: starserver.activeWorlds()
        version: starserver.version
        maxPlayers: starserver.config.maxPlayers ? 8 # guess at default?
        worldsExplored: worldCount
        playersSeen: playerCount
        public: starserver.isPublic()
        css: config.customCss
        features: config.features
      res.send resData
      return next()

# Used by starbound-servers.net.  Don't change data output without confirming
# change with malobre
getPlayersOnline = (req, res, next) ->
  plist = []
  for i of starserver.players
    plist.push(nickname: starserver.players[i])
  resData =
    playercount: starserver.players.length
    playerlist: plist
  res.send resData
  next()

getWorlds = ( req, res, next ) ->
  starserver.allWorlds ( worlds ) ->
    res.send worlds
    next()

getWorldsPopular = ( req, res, next ) ->
  starserver.allWorlds ( worlds ) ->
    sortByVisits = ( world ) ->
      v = world.numLoads ? 0
      return -v
    sorted = _.sortBy worlds, sortByVisits
    res.send sorted[0..9]
    next()

getPlayers = ( req, res, next ) ->
  starserver.allPlayers ( players ) ->
    res.send players
    next()

getChat = ( req, res, next ) ->
  res.send starserver.chat
  next()

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
  fs.readFile __dirname + '/../public/index.html', (err, data ) ->
    if err
      next err
      return
    res.setHeader 'Content-Type', 'text/html'
    res.writeHead 200
    res.end data
    next()

server.get( '/server/status', getServerStatus )

server.get( '/server/chat', getChat )

server.get( '/server/players', getPlayers )

server.get( '/server/players/online', getPlayersOnline )
server.get( '/server/playerList', getPlayersOnline )

server.get( '/server/worlds', getWorlds )
server.get( '/server/worlds/popular', getWorldsPopular )

ioOpts =
  'log level': 1

io = socketio.listen server, ioOpts

server.listen config.listenPort, ->
  console.log "%s listening on port %s", server.name, server.url

