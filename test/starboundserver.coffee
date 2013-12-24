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

  it 'should not allow check frequency lower than 1 second', ->
    opts =
      checkFrequency: 0.1
    ( ->
      server = new StarboundServer opts
    ).should.throw

  it 'should return an error if it cannot find config file', ( done ) ->
    server = new StarboundServer badOpts
    server.init ( err ) ->
      err.should.have.property "message"
      err.message.should.startWith "Unable to read config file"
      done()

  it 'should parse the config JSON file', ( done ) ->
    mockserv = new MockServer()
    mockserv.start()
    server = new StarboundServer mockserv.getOpts()
    server.init ( err ) ->
      server.config.gamePort.should.equal mockserv.configData.gamePort
      server.config.audioChannels.should.equal mockserv.configData.audioChannels
      server.config.sampleRate.should.equal mockserv.configData.sampleRate
      mockserv.stop()
      done()


