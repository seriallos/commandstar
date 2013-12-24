{ StarboundServer, ServerLog, MockServer } = require './helpers/index.coffee'

describe 'StarboundServer', ->

  badOpts =
    binPath: "/foo/bin"
    assetsPath: "/foo/assets"
    dataPath: "/foo/data"
    configPath: "/foo/config"
    checkStatus: true
    checkFrequency: 999

  it 'should use sane defaults', ->
    server = new StarboundServer()
    server.should.have.property "binPath", "/opt/starbound/bin"
    server.should.have.property "assetsPath", "/opt/starbound/assets"
    server.should.have.property "dataPath", "/opt/starbound/bin/universe"
    defaultConfigPath =  "/opt/starbound/bin/starbound.config"
    server.should.have.property "configPath", defaultConfigPath
    server.should.have.property "checkStatus", false
    server.should.have.property "checkFrequency", 60

  it 'should allow option overrides', ->
    server = new StarboundServer badOpts
    server.should.have.property "binPath", badOpts.binPath
    server.should.have.property "assetsPath", badOpts.assetsPath
    server.should.have.property "dataPath", badOpts.dataPath
    server.should.have.property "configPath", badOpts.configPath
    server.should.have.property "checkStatus", badOpts.checkStatus
    server.should.have.property "checkFrequency", badOpts.checkFrequency

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

describe 'StarboundServer - MockServer Tests', ->

  mockserv = null
  server = null

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
  #  server.on 'statusChange', (status) ->
  #    status.should.equal server.monitor.STATUS_UP
  #    done()
  #  server.init ( err ) ->
  #    mockserv.start()

  it 'should emit statusChange events on server shutdown', ( done ) ->
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      server.on 'statusChange', (status) ->
        status.should.equal server.monitor.STATUS_DOWN
        done()
      mockserv.stop()




