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

  beforeEach ( done ) ->
    mockserv = new MockServer()
    mockserv.start()
    done()

  afterEach ( done ) ->
    mockserv.stop()
    mockserv = null
    log = null
    done()

  it 'should emit events on player connect from previous log', ( done ) ->
    mockserv.logConnectPlayer 1, 'dave'
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      # for this test, the playerConnect event will happen while
      # init is running so we need to wait to call done() until init
      # has finished
      done()
    log.on "playerConnect", ( playerId, fromActiveLog ) ->
      playerId.should.equal 'dave'
      fromActiveLog.should.be.false

  it 'should emit events on player connect from tailing the log', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      mockserv.logConnectPlayer 1, 'dave'
    log.on "playerConnect", ( playerId, fromActiveLog ) ->
      playerId.should.equal 'dave'
      fromActiveLog.should.be.true
      # but for this test, we're writing to the log after init is done which
      # means the playerConnect event won't fire until after init() is
      # completely finished which is why done() is here
      done()

  it 'should emit events on player disconnect from previous log', ( done ) ->
    mockserv.logDisconnectPlayer 1, 'dave'
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      done()
    log.on "playerDisconnect", ( playerId, fromActiveLog ) ->
      playerId.should.equal 'dave'
      fromActiveLog.should.be.false

  it 'should emit events on player disconnect from the log tail', ( done ) ->
    log = new ServerLog mockserv.getOpts()
    log.init ( ) ->
      mockserv.logDisconnectPlayer 1, 'dave'
    log.on "playerDisconnect", ( playerId, fromActiveLog ) ->
      playerId.should.equal 'dave'
      fromActiveLog.should.be.true
      done()



