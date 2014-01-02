{ ConfigValidator } = require './helpers/index.coffee'

os = require 'os'
fs = require 'fs'

should = require 'should'

_ = require 'lodash'

baseTmpDir = os.tmpdir()

goodConfig =
  serverName: "Test Server"
  serverDescription: "Server Description"
  starbound:
    binPath: '/tmp/bin'
    assetsPath: '/tmp/assets'
    dataPath: '/tmp/data'
    logFile: '/tmp/server.log'
    configFile: '/tmp/starbound.config'
  features:
    serverStatus: false
    activeSystems: true
    apiFooter: true
  ignoreChatPrefixes: '/#'
  listenPort: 8181
  maxRecentChatMessages: 999
  serverStatus:
    checkFrequency: 444
  customCss: [
    'test.css'
  ]
  hipchat:
    token: null
    room: 'Starbound'
    user: 'Server'
    color: 'yellow'
    notify: false
  irc:
    server: 'test.irc'
    nick: 'StarBot'
    channel: '#starbound'
    user: null
    password: null
  datastore:
    dataPath: './data'

describe 'ConfigValidator', ->
  testConfig = null
  tmpDir = null

  setupTmpFiles = ->
    r = Math.floor( Math.random() * 9999999 )
    tmpDir = "#{baseTmpDir}/#{r}"


  beforeEach ( done ) ->
    # clone the good config into testConfig before each test
    testConfig = _.cloneDeep goodConfig
    setupTmpFiles()
    done()

  afterEach ( done ) ->
    testConfig = null
    tmpDir = null
    done()

  it 'fails if binPath is not set', ( done ) ->
    testConfig.starbound.binPath = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'fails if assetsPath is not set', ( done ) ->
    testConfig.starbound.assetsPath = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'fails if dataPath is not set', ( done ) ->
    testConfig.starbound.dataPath = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'fails if logFile is not set', ( done ) ->
    testConfig.starbound.logFile = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'fails if configFile is not set', ( done ) ->
    testConfig.starbound.configFile = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'fails if binPath does not exist', ( done ) ->
    testConfig.starbound.binPath = "/path/that/does/not/exist"
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'fails if assetsPath does not exist', ( done ) ->
    testConfig.starbound.assetsPath = "/path/that/does/not/exist"
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'fails if dataPath does not exist', ( done ) ->
    testConfig.starbound.dataPath = "/path/that/does/not/exist"
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'fails if logFile does not exist', ( done ) ->
    testConfig.starbound.logFile = "/path/that/does/not/exist"
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'fails if configFile does not exist', ( done ) ->
    testConfig.starbound.configFile = "/path/that/does/not/exist"
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()


