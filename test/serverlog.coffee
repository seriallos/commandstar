{ ServerInfo, ServerLog, MockServer } = require './helpers/index.coffee'

describe 'ServerLog', ->
  it 'requires opts in constructor', ->
    ( ->
      info = new ServerLog()
    ).should.throw 'ServerLog requires options'

  it 'requires a log file path', ->
    ( ->
      info = new ServerLog( { foo: 'bar' } )
    ).should.throw 'ServerLog requires logFile in constructor options'

describe 'ServerLog using MockServer', ->

  mockserv = null
  log = null
  writeDelay = 5

  testWorld =
    sector: 'foo'
    x: '99'
    y: '100'
    z: '-88'
    planet: '1'
    satellite: '2'

  beforeEach ( done ) ->
    mockserv = new MockServer()
    mockserv.start ->
      done()

  afterEach ( done ) ->
    mockserv.stop ->
      mockserv = null
      log.stopWatching()
      log = null
      done()

  it 'should emit events on player connect from previous log', ( done ) ->
    eventFired = false
    mockserv.logConnectPlayer 1, 'dave'
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      # for this test, the playerConnect event will happen while
      # init is running so we need to wait to call done() until init
      # has finished
      eventFired.should.be.true
      done()
    log.on "playerConnect", ( playerId, fromActiveLog ) ->
      eventFired = true
      playerId.should.equal 'dave'
      fromActiveLog.should.be.false

  it 'should emit events on player connect from tailing the log', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "playerConnect", ( playerId, fromActiveLog ) ->
      playerId.should.equal 'dave'
      fromActiveLog.should.be.true
      # but for this test, we're writing to the log after init is done which
      # means the playerConnect event won't fire until after init() is
      # completely finished which is why done() is here
      done()
    log.init ( ) ->
      # this is awful but seems maybe necessary
      # I'm not 100% sure, but these tests were failing often enough that I
      # spent some time debugging. I believe that issuing the write to the
      # mock log immediately after the tail start could sometimes result
      # in the write happening before the logtail could detect the initial
      # state of the file.
      # hence, a small delay between init'ing the ServerLog and issuing the
      # mock server log write.
      # The pattern is repeated for every log tail test.
      f = ( ) -> mockserv.logConnectPlayer 1, 'dave'
      setTimeout f, writeDelay

  it 'should emit events on player disconnect from previous log', ( done ) ->
    eventFired = false
    mockserv.logDisconnectPlayer 1, 'dave'
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      eventFired.should.be.true
      done()
    log.on "playerDisconnect", ( playerId, fromActiveLog ) ->
      eventFired = true
      playerId.should.equal 'dave'
      fromActiveLog.should.be.false

  it 'should emit events on player disconnect from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "playerDisconnect", ( playerId, fromActiveLog ) ->
      playerId.should.equal 'dave'
      fromActiveLog.should.be.true
      done()
    log.init ( ) ->
      f = ( ) -> mockserv.logDisconnectPlayer 1, 'dave'
      setTimeout f, writeDelay

  it 'should emit events on player chat from previous log', ( done ) ->
    eventFired = false
    mockserv.logChat 'dave', 'hello world!'
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      eventFired.should.be.true
      done()
    log.on "chat", ( who, what, whn, fromActiveLog ) ->
      eventFired = true
      who.should.equal 'dave'
      what.should.equal 'hello world!'
      fromActiveLog.should.be.false

  it 'should emit events on player chat from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "chat", ( who, what, whn, fromActiveLog ) ->
      who.should.equal 'dave'
      what.should.equal 'hello world!'
      fromActiveLog.should.be.true
      done()
    log.init ( ) ->
      f = ( ) -> mockserv.logChat 'dave', 'hello world!'
      setTimeout f, writeDelay

  it 'should emit events on server start from previous log', ( done ) ->
    eventFired = false
    mockserv.logServerStart()
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      eventFired.should.be.true
      done()
    log.on "serverStart", ( whn, fromActiveLog ) ->
      eventFired = true
      fromActiveLog.should.be.false

  it 'should emit events on server start from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "serverStart", ( whn, fromActiveLog ) ->
      fromActiveLog.should.be.true
      done()
    log.init ( ) ->
      f = ( ) -> mockserv.logServerStart()
      setTimeout f, writeDelay

  it 'should emit events on server stop from previous log', ( done ) ->
    eventFired = false
    mockserv.logServerStop()
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      eventFired.should.be.true
      done()
    log.on "serverStop", ( whn, fromActiveLog ) ->
      eventFired = true
      fromActiveLog.should.be.false

  it 'should emit events on server stop from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "serverStop", ( whn, fromActiveLog ) ->
      fromActiveLog.should.be.true
      done()
    log.init ( ) ->
      f = ( ) -> mockserv.logServerStop()
      setTimeout f, writeDelay

  it 'should emit events on server version from previous log', ( done ) ->
    eventFired = false
    mockserv.logServerVersion "Beta v. Test Koala"
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      eventFired.should.be.true
      done()
    log.on "serverVersion", ( version, fromActiveLog ) ->
      eventFired = true
      fromActiveLog.should.be.false
      version.should.be.equal "Beta v. Test Koala"

  it 'should emit events on server version from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "serverVersion", ( version, fromActiveLog ) ->
      fromActiveLog.should.be.true
      version.should.be.equal "Beta v. Test Koala"
      done()
    log.init ( ) ->
      f = ( ) -> mockserv.logServerVersion "Beta v. Test Koala"
      setTimeout f, writeDelay

  it 'should emit events on server segfault from previous log', ( done ) ->
    eventFired = false
    mockserv.logSegfault()
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      eventFired.should.be.true
      done()
    log.on "serverCrash", ( crashLine, whn, fromActiveLog ) ->
      eventFired = true
      fromActiveLog.should.be.false

  it 'should emit events on server segfault from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "serverCrash", ( crashLine, whn, fromActiveLog ) ->
      fromActiveLog.should.be.true
      done()
    log.init ( ) ->
      f = ( ) -> mockserv.logSegfault()
      setTimeout f, writeDelay

  it 'should emit events on world load from previous log', ( done ) ->
    eventFired = false
    mockserv.loadWorld(
      testWorld.sector,
      testWorld.x,
      testWorld.y,
      testWorld.z,
      testWorld.planet,
      testWorld.satellite
    )
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      eventFired.should.be.true
      done()
    log.on "worldLoad", ( world, fromActiveLog ) ->
      eventFired = true
      world.sector.should.equal testWorld.sector
      world.x.should.equal testWorld.x
      world.y.should.equal testWorld.y
      world.z.should.equal testWorld.z
      world.planet.should.equal testWorld.planet
      world.satellite.should.equal testWorld.satellite
      fromActiveLog.should.be.false

  it 'should emit events on world load from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "worldLoad", ( world, fromActiveLog ) ->
      fromActiveLog.should.be.true
      world.sector.should.equal testWorld.sector
      world.x.should.equal testWorld.x
      world.y.should.equal testWorld.y
      world.z.should.equal testWorld.z
      world.planet.should.equal testWorld.planet
      world.satellite.should.equal testWorld.satellite
      done()
    log.init ( ) ->
      f = ( ) -> mockserv.loadWorld(
        testWorld.sector,
        testWorld.x,
        testWorld.y,
        testWorld.z,
        testWorld.planet,
        testWorld.satellite
      )
      setTimeout f, writeDelay

  it 'should emit events on world unload from previous log', ( done ) ->
    eventFired = false
    mockserv.unloadWorld(
      testWorld.sector,
      testWorld.x,
      testWorld.y,
      testWorld.z,
      testWorld.planet,
      testWorld.satellite
    )
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      eventFired.should.be.true
      done()
    log.on "worldUnload", ( world, fromActiveLog ) ->
      eventFired = true
      world.sector.should.equal testWorld.sector
      world.x.should.equal testWorld.x
      world.y.should.equal testWorld.y
      world.z.should.equal testWorld.z
      world.planet.should.equal testWorld.planet
      world.satellite.should.equal testWorld.satellite
      fromActiveLog.should.be.false

  it 'should emit events on world unload from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "worldUnload", ( world, fromActiveLog ) ->
      fromActiveLog.should.be.true
      world.sector.should.equal testWorld.sector
      world.x.should.equal testWorld.x
      world.y.should.equal testWorld.y
      world.z.should.equal testWorld.z
      world.planet.should.equal testWorld.planet
      world.satellite.should.equal testWorld.satellite
      done()
    log.init ( ) ->
      f = ( ) -> mockserv.unloadWorld(
        testWorld.sector,
        testWorld.x,
        testWorld.y,
        testWorld.z,
        testWorld.planet,
        testWorld.satellite
      )
      setTimeout f, writeDelay

  it 'should emit event on player uuid line from previous log', ( done ) ->
    eventFired = false
    mockserv.logPlayerUuid 'seriallos', '32a3dc1eef39131740a1d6b559b80031'
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      eventFired.should.be.true
      done()
    log.on "playerUuid", ( playerName, playerUuid, fromActiveLog ) ->
      eventFired = true
      playerName.should.equal 'seriallos'
      playerUuid.should.equal '32a3dc1eef39131740a1d6b559b80031'
      fromActiveLog.should.be.false

  it 'should emit events on player disconnect from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.on "playerUuid", ( playerName, playerUuid, fromActiveLog ) ->
      playerName.should.equal 'seriallos'
      playerUuid.should.equal '32a3dc1eef39131740a1d6b559b80031'
      fromActiveLog.should.be.true
      done()
    log.init ( ) ->
      f = ( ) ->
        mockserv.logPlayerUuid 'seriallos', '32a3dc1eef39131740a1d6b559b80031'
      setTimeout f, writeDelay
