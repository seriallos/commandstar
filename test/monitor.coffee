{ MockServer, ServerMonitor } = require './helpers/index.coffee'
net = require 'net'

describe 'ServerMonitor', ->
  testOpts =
    gameHost: 'notarealwebsite.goo.bar.com.dev'
    gamePort: 33333
    checkFrequency: 999

  it 'should have sane defaults', ->
    srvmon = new ServerMonitor()
    srvmon.should.have.property "gameHost", 'localhost'
    srvmon.should.have.property "gamePort", 21025
    srvmon.should.have.property "checkFrequency", 300

  it 'should allow constructor overrides', ->
    srvmon = new ServerMonitor( testOpts )
    srvmon.should.have.property "gameHost", testOpts.gameHost
    srvmon.should.have.property "gamePort", testOpts.gamePort
    srvmon.should.have.property "checkFrequency", testOpts.checkFrequency

  it 'emits an event when status changes', ( done ) ->
    srvmon = new ServerMonitor testOpts
    srvmon.on 'statusChange', ( status ) ->
      status.should.equal 1
      done()
    srvmon.setStatus 1

  it 'should create an interval ID when watching', ( done ) ->
    srvmon = new ServerMonitor( testOpts )
    srvmon.watch ->
      srvmon.watchIntervalId.should.have.property "_idleTimeout"
      srvmon.watchIntervalId.should.have.property "_repeat", true
      timeout = 1000 * testOpts.checkFrequency
      srvmon.watchIntervalId._idleTimeout.should.equal timeout
      done()

  it 'should clear interval ID on unwatch', ( done ) ->
    srvmon = new ServerMonitor( testOpts )
    srvmon.watch ->
      srvmon.watchIntervalId.should.not.be.null
      srvmon.unwatch()
      srvmon.should.have.property 'watchIntervalId', null
      srvmon.unwatch()
      done()


describe 'ServerMonitor with MockServer', ->

  testOpts =
    gameHost: 'notarealwebsite.goo.bar.com.dev'
    gamePort: 33333
    checkFrequency: 999

  mockserv = null
  srvmon = null

  beforeEach ( done ) ->
    mockserv = new MockServer()
    mockserv.start ->
      done()

  afterEach ( done ) ->
    # make sure watch is cleared if it was started
    if srvmon
      srvmon.unwatch()
    mockserv.stop ->
      mockserv = null
      done()

  it 'should return down and error when server not running', ( done ) ->
    # runs against bad hostname
    srvmon = new ServerMonitor testOpts
    srvmon.check ( err, status ) ->
      status.should.equal 0
      done()

  it 'should return up when port is listening', ( done ) ->
    srvmon = new ServerMonitor mockserv.getOpts()
    srvmon.check (err, status) ->
      status.should.equal 1
      done()

  it 'should emit statusChange event on first check()', ( done ) ->
    srvmon = new ServerMonitor mockserv.getOpts()
    # check() will call setStatus() which should emit a change event
    srvmon.check (err, status) ->
      status.should.equal 1
    srvmon.on 'statusChange', ( status ) ->
      status.should.equal 1
      done()

  it 'should emit statusChange when checking after stopping', ( done ) ->
    srvmon = new ServerMonitor mockserv.getOpts()
    srvmon.check (err, status) ->
      status.should.equal 1
      srvmon.status.should.equal 1
      # change the listen port
      srvmon.gamePort = 99999
      # check again, this port is too high and shouldn't work
      srvmon.check ( err, status ) ->
        status.should.equal 0
        srvmon.status.should.equal 0
      # this listener is bound after the first check so it should only fire
      # after the change to port 99999
      srvmon.on 'statusChange', ( status ) ->
        status.should.equal 0
        done()

  it 'should emit change event when watching', ( done ) ->
    mockOpts = mockserv.getOpts()
    # check every 10ms
    mockOpts.checkFrequency = 0.01
    srvmon = new ServerMonitor mockOpts
    srvmon.watch ->
      srvmon.status.should.equal srvmon.STATUS_UP
      srvmon.on 'statusChange', ( status ) ->
        status.should.equal srvmon.STATUS_DOWN
        srvmon.unwatch()
        done()
      mockserv.stop()



