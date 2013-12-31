{
  StarboundServer,
  ServerLog,
  MockServer,
  Datastore
} = require './helpers/index.coffee'

_ = require 'underscore'

describe 'StarboundServer', ->

  badOpts =
    binPath: "/foo/bin"
    assetsPath: "/foo/assets"
    dataPath: "/foo/data"
    configPath: "/foo/config"
    logFile: '/tmp/log'
    checkStatus: true
    checkFrequency: 999
    maxChatSize: 22

  it 'should use sane defaults', ->
    server = new StarboundServer()
    server.should.have.property "binPath", "/opt/starbound/bin"
    server.should.have.property "assetsPath", "/opt/starbound/assets"
    server.should.have.property "dataPath", "/opt/starbound/bin/universe"
    defaultLogFile =  "/opt/starbound/bin/starbound_server.log"
    server.should.have.property "logFile", defaultLogFile
    defaultConfigPath =  "/opt/starbound/bin/starbound.config"
    server.should.have.property "configPath", defaultConfigPath
    server.should.have.property "checkStatus", false
    server.should.have.property "checkFrequency", 60
    server.should.have.property "maxChatSize", 100

  it 'should allow option overrides', ->
    server = new StarboundServer badOpts
    server.should.have.property "binPath", badOpts.binPath
    server.should.have.property "assetsPath", badOpts.assetsPath
    server.should.have.property "dataPath", badOpts.dataPath
    server.should.have.property "configPath", badOpts.configPath
    server.should.have.property "logFile", badOpts.logFile
    server.should.have.property "checkStatus", badOpts.checkStatus
    server.should.have.property "checkFrequency", badOpts.checkFrequency
    server.should.have.property "maxChatSize", badOpts.maxChatSize

    opts =
      binPath: "/foo/bin"
    server = new StarboundServer opts
    server.should.have.property "binPath", opts.binPath
    server.should.have.property "assetsPath", "/opt/starbound/assets"

  it 'should return an error if it cannot find config file', ( done ) ->
    server = new StarboundServer badOpts
    server.init ( err ) ->
      err.should.have.property "message"
      err.message.should.startWith "Unable to read config file"
      done()

describe 'StarboundServer Events - MockServer Tests', ->

  mockserv = null
  server = null
  writeDelay = 5

  testWorld =
    sector: 'grabble'
    x: '-777'
    y: '6666'
    z: '321'
    planet: '9'
    satellite: '11'

  beforeEach ( done ) ->
    mockserv = new MockServer()
    mockserv.start ->
      done()

  afterEach ( done ) ->
    # make sure watch is cleared if it was started
    if server
      server.reset()
    server = null
    mockserv.stop ->
      mockserv = null
      done()

  it 'should parse the config JSON file', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      server.config.gamePort.should.equal mockserv.configData.gamePort
      server.config.audioChannels.should.equal mockserv.configData.audioChannels
      server.config.sampleRate.should.equal mockserv.configData.sampleRate
      mockserv.stop()
      done()

  # MockServer may not be structured to make this work without a lot of
  # fighting
  #
  #it 'should emit statusChange events on server startup', ( done ) ->
  #  # stop the server when we start
  #  server = new StarboundServer mockserv.getOpts()
  #  server.on 'start', (status) ->
  #    done()
  #  server.init ( err ) ->
  #    mockserv.start()

  it 'should emit "stop" event on server port going dead', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      server.on 'stop', ( whn ) ->
        done()
      mockserv.stop()

  it 'should emit "playerConnect" event on player connect', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on "playerConnect", ( playerId ) ->
      playerId.should.equal 'dave'
      done()
    server.init ( err ) ->
      f = ( ) -> mockserv.logConnectPlayer 1, 'dave'
      setTimeout f, writeDelay

  it 'should emit "playerDisconnect" event on player disconnect', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on "playerDisconnect", ( playerId ) ->
      playerId.should.equal 'dave'
      done()
    server.init ( err ) ->
      f = ( ) -> mockserv.logDisconnectPlayer 1, 'dave'
      setTimeout f, writeDelay

  it 'should emit "chat" event on live player chat', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on "chat", ( who, what, whn ) ->
      if who != @serverChatName
        who.should.equal 'dave'
        what.should.equal 'hello world!'
        done()
    server.init ( err ) ->
      f = ( ) -> mockserv.logChat 'dave', 'hello world!'
      setTimeout f, writeDelay

  it 'should emit "version" event on live server version', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on "version", ( version ) ->
      version.should.be.equal "Beta v. Test Koala"
      done()
    server.init ( err ) ->
      f = ( ) -> mockserv.logServerVersion "Beta v. Test Koala"
      setTimeout f, writeDelay

  it 'should emit "crash" event on live server segfault', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on "stop", ( whn, why ) ->
      why.should.equal 'log crash'
      done()
    server.init ( ) ->
      f = ( ) -> mockserv.logSegfault()
      setTimeout f, writeDelay

  it 'should emit "worldLoad" event on live world load', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on "worldLoad", ( world ) ->
      world.sector.should.equal testWorld.sector
      world.x.should.equal testWorld.x
      world.y.should.equal testWorld.y
      world.z.should.equal testWorld.z
      world.planet.should.equal testWorld.planet
      world.satellite.should.equal testWorld.satellite
      done()
    server.init ( ) ->
      f = ( ) -> mockserv.loadWorld(
        testWorld.sector,
        testWorld.x,
        testWorld.y,
        testWorld.z,
        testWorld.planet,
        testWorld.satellite
      )
      setTimeout f, writeDelay

  it 'should emit "worldUnload" event on live world unload', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on "worldUnload", ( world ) ->
      world.sector.should.equal testWorld.sector
      world.x.should.equal testWorld.x
      world.y.should.equal testWorld.y
      world.z.should.equal testWorld.z
      world.planet.should.equal testWorld.planet
      world.satellite.should.equal testWorld.satellite
      done()
    server.init ( ) ->
      f = ( ) -> mockserv.unloadWorld(
        testWorld.sector,
        testWorld.x,
        testWorld.y,
        testWorld.z,
        testWorld.planet,
        testWorld.satellite
      )
      setTimeout f, writeDelay

  it 'should emit one stop event on shutdown message and port DC', ( done ) ->
    eventsFired = 0
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      server.on 'stop', ( whn, why ) ->
        eventsFired += 1
      mockserv.logServerStop()
      mockserv.stop()
      f = ( ) ->
        eventsFired.should.equal 1
        done()
      setTimeout f, 10

describe 'StarboundServer State - MockServer Tests', ->
  mockserv = null
  server = null
  testDelay = 5
  testWorld =
    sector: 'charlie'
    x: '1'
    y: '2'
    z: '3'
    planet: '77'
    satellite: '88'

  beforeEach ( done ) ->
    mockserv = new MockServer()
    mockserv.start ->
      done()

  afterEach ( done ) ->
    # make sure watch is cleared if it was started
    if server
      server.reset()
    server = null
    mockserv.stop ->
      mockserv = null
      done()

  it 'should know server is down on port disconnect', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      mockserv.stop()
      f = ( ) ->
        server.status.should.equal server.monitor.STATUS_DOWN
        done()
      setTimeout f, testDelay

  it 'should know server is down on shutdown message', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      mockserv.logServerStop()
      f = ( ) ->
        server.status.should.equal server.monitor.STATUS_DOWN
        done()
      setTimeout f, testDelay

  it 'should track online players', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      mockserv.logConnectPlayer 1, 'alice'
      mockserv.logConnectPlayer 2, 'bob'
      f = ( ) ->
        # make sure players logged in are tracked
        server.players.should.have.length 2
        server.players.should.include 'alice'
        server.players.should.include 'bob'

        mockserv.logDisconnectPlayer 1, 'alice'
        mockserv.logConnectPlayer 3, 'charlie'
        mockserv.logConnectPlayer 4, 'dave'
        ff = ( ) ->
          server.players.should.have.length 3
          server.players.should.not.include 'alice'
          server.players.should.include 'bob'
          server.players.should.include 'charlie'
          server.players.should.include 'dave'
          done()
        setTimeout ff, testDelay
      setTimeout f, testDelay

  it 'should clear players after server status change', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      mockserv.logConnectPlayer 1, 'alice'
      mockserv.logConnectPlayer 2, 'bob'
      mockserv.logServerStop()
      f = ( ) ->
        # make sure players logged in are tracked
        server.players.should.have.length 0
        server.players.should.not.include 'alice'
        server.players.should.not.include 'bob'
        done()
      setTimeout f, testDelay

  it 'should clear players after server crash', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      mockserv.logConnectPlayer 1, 'alice'
      mockserv.logConnectPlayer 2, 'bob'
      mockserv.logSegfault()
      f = ( ) ->
        # make sure players logged in are tracked
        server.players.should.have.length 0
        server.players.should.not.include 'alice'
        server.players.should.not.include 'bob'
        done()
      setTimeout f, testDelay

  it 'should log recent chat', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on 'chat', ( who, what, whn, live ) ->
      # TODO: This feels wrong
      if who != @serverChatName
        chatLen = server.chat.length
        lastMsg = server.chat[ chatLen - 1 ]
        lastMsg.should.have.property 'who', 'dave'
        lastMsg.should.have.property 'what', 'hello'
        done()
    server.init ( err ) ->
      mockserv.logChat 'dave', 'hello'

  it 'should only keep configurable amount of chat messages', ( done ) ->
    opts = mockserv.getOpts()
    opts.maxChatSize = 1
    numMsgs = 0
    server = new StarboundServer opts
    server.on 'chat', ( who, what, whn ) ->
      if who != @serverChatName
        numMsgs += 1
        if numMsgs == 3
          chatLen = server.chat.length
          lastMsg = server.chat[ chatLen - 1 ]
          chatLen.should.equal 1
          lastMsg.should.have.property 'who', 'dave'
          lastMsg.should.have.property 'what', 'bang'
          done()
    server.init ( err ) ->
      mockserv.logChat 'dave', 'hello'
      mockserv.logChat 'dave', 'world'
      mockserv.logChat 'dave', 'bang'

  it 'should add world on load', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on 'worldLoad', ( world ) ->
      server.worlds.should.have.length 1
      w = server.worlds[ server.worlds.length - 1 ]
      w.should.have.property 'sector', testWorld.sector
      w.should.have.property 'x', testWorld.x
      w.should.have.property 'y', testWorld.y
      w.should.have.property 'z', testWorld.z
      w.should.have.property 'planet', testWorld.planet
      w.should.have.property 'satellite', testWorld.satellite
      w.should.have.property 'active', true
      done()
    server.init ( err ) ->
      mockserv.loadWorld testWorld

  it 'should set world to inactive on unload', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.on 'worldLoad', ( world ) ->
      server.worlds.should.have.length 1
      w = server.worlds[ server.worlds.length - 1 ]
    server.on 'worldUnload', ( world ) ->
      server.worlds.should.have.length 1
      w = server.worlds[ server.worlds.length - 1 ]
      w.should.have.property 'active', false
      done()
    server.init ( err ) ->
      mockserv.loadWorld testWorld
      mockserv.unloadWorld testWorld

  it 'should clear worlds after status change', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    loadFired = false
    server.on 'worldLoad', ( world ) ->
      loadFired = true
      server.worlds.should.have.length 1
    server.on 'stop', ( whn, why ) ->
      loadFired.should.be.true
      why.should.equal 'monitor'
      server.worlds.should.have.length 0
      done()
    server.init ( err ) ->
      mockserv.loadWorld testWorld
      # delay server stop to let the load event fire
      f = ->
        mockserv.stop()
      setTimeout f, testDelay

  it 'should clear worlds after server crash', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    loadFired = false
    server.on 'worldLoad', ( world ) ->
      loadFired = true
      server.worlds.should.have.length 1
    server.on 'stop', (whn, why) ->
      loadFired.should.be.true
      server.worlds.should.have.length 0
      why.should.equal 'log crash'
      done()
    server.init ( err ) ->
      mockserv.loadWorld testWorld
      # delay server stop to let the load event fire
      f = ->
        mockserv.logSegfault()
      setTimeout f, testDelay


describe 'StarboundServer State - Datastore Tests', ->

  # These tests exercise the NeDB persistence layer.  Each test has a mock
  # server, StarboundServer, and in-memory database setup to make sure the DB is
  # updated as expected.

  mockserv = null
  server = null
  db = null

  makeDb = ->
    db = {}
    db.players = new Datastore( { autoload: true } )
    db.worlds = new Datastore( { autoload: true } )
    return db

  beforeEach ( done ) ->
    mockserv = new MockServer()
    mockserv.start ->
      db = makeDb()
      opts = mockserv.getOpts()
      opts.db = makeDb()
      server = new StarboundServer opts
      server.init (err ) ->
        done()

  afterEach ( done ) ->
    # make sure watch is cleared if it was started
    if server
      server.reset()
    server = null
    db = null
    mockserv.stop ->
      mockserv = null
      done()


  it 'stores players and num logins in the DB', ( done ) ->
    mockserv.logConnectPlayer 1, 'alice'
    mockserv.logConnectPlayer 2, 'bob'
    mockserv.logDisconnectPlayer 2, 'bob'
    mockserv.logConnectPlayer 2, 'bob'
    mockserv.logConnectPlayer 3, 'trevor'
    # need to wait for IO and log tail to catch up
    f = ->
      db.players.find {}, ( err, docs ) ->
        docs.should.have.length 3

        alice = _.find docs, ( d ) -> d.name == 'alice'
        alice.should.have.property 'name', 'alice'
        alice.should.have.property 'numLogins', 1
        alice.should.have.property 'lastLogin'

        bob = _.find docs, ( d ) -> d.name == 'bob'
        bob.should.have.property 'name', 'bob'
        bob.should.have.property 'numLogins', 2
        bob.should.have.property 'lastLogin'
        bob.should.have.property 'lastLogout'

        trevor = _.find docs, ( d ) -> d.name == 'trevor'
        trevor.should.have.property 'name', 'trevor'
        trevor.should.have.property 'numLogins', 1

        done()
    setTimeout f, 5

  it 'stores worlds and num loads in the DB', ( done ) ->
    worldCharlie =
      sector: 'charlie'
      x: '1'
      y: '2'
      z: '3'
      planet: '4'
      satellite: '5'
    worldEcho =
      sector: 'echo'
      x: '-1'
      y: '-2'
      z: '-3'
      planet: '10'
      satellite: null
    mockserv.loadWorld worldCharlie
    mockserv.unloadWorld worldCharlie
    mockserv.loadWorld worldCharlie
    mockserv.loadWorld worldEcho
    # need to wait for IO and log tail to catch up
    f = ->
      db.worlds.find {}, ( err, docs ) ->
        docs.should.have.length 2

        charlie = _.findWhere docs, worldCharlie
        charlie.should.have.property 'sector', worldCharlie.sector
        charlie.should.have.property 'x', worldCharlie.x
        charlie.should.have.property 'y', worldCharlie.y
        charlie.should.have.property 'z', worldCharlie.z
        charlie.should.have.property 'planet', worldCharlie.planet
        charlie.should.have.property 'satellite', worldCharlie.satellite
        charlie.should.have.property 'numLoads', 2
        charlie.should.have.property 'lastLoaded'
        charlie.should.have.property 'lastUnloaded'

        echo = _.findWhere docs, worldEcho
        echo.should.have.property 'sector', worldEcho.sector
        echo.should.have.property 'x', worldEcho.x
        echo.should.have.property 'y', worldEcho.y
        echo.should.have.property 'z', worldEcho.z
        echo.should.have.property 'planet', worldEcho.planet
        echo.should.have.property 'satellite', worldEcho.satellite
        echo.should.have.property 'numLoads', 1
        echo.should.have.property 'lastLoaded'

        done()
    setTimeout f, 5

