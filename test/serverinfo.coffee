{ ServerInfo, ServerLog, MockServer } = require './helpers/index.coffee'

describe 'ServerInfo', ->

  badOpts =
    binPath: "/foo/bin"
    assetsPath: "/foo/assets"
    dataPath: "/foo/data"
    configPath: "/foo/config"

  it 'should use sane defaults', ->
    info = new ServerInfo()
    info.should.have.property "binPath", "/opt/starbound/bin"
    info.should.have.property "assetsPath", "/opt/starbound/assets"
    info.should.have.property "dataPath", "/opt/starbound/bin/universe"
    info.should.have.property "configPath", "/opt/starbound/bin/starbound.config"

  it 'should allow option overrides', ->
    info = new ServerInfo badOpts
    info.should.have.property "binPath", badOpts.binPath
    info.should.have.property "assetsPath", badOpts.assetsPath
    info.should.have.property "dataPath", badOpts.dataPath
    info.should.have.property "configPath", badOpts.configPath

    opts =
      binPath: "/foo/bin"
    info = new ServerInfo opts
    info.should.have.property "binPath", opts.binPath
    info.should.have.property "assetsPath", "/opt/starbound/assets"

  it 'should return an error if it cannot find config file', ( done ) ->
    info = new ServerInfo badOpts
    info.init ( err ) ->
      err.should.have.property "message"
      err.message.should.startWith "Unable to read config file"
      done()

  it 'should parse the config JSON file', ( done ) ->
    mockserv = new MockServer()
    mockserv.start()
    info = new ServerInfo mockserv.getOpts()
    info.init ( err ) ->
      info.config.gamePort.should.equal mockserv.configData.gamePort
      info.config.audioChannels.should.equal mockserv.configData.audioChannels
      info.config.sampleRate.should.equal mockserv.configData.sampleRate
      mockserv.stop()
      done()


