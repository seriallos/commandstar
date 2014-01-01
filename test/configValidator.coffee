{ ConfigValidator } = require './helpers/index.coffee'

should = require 'should'

_ = require 'lodash'

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

  beforeEach ( done ) ->
    testConfig = _.cloneDeep goodConfig
    done()

  afterEach ( done ) ->
    testConfig = null
    done()

  it 'throws if binPath is not set', ( done ) ->
    testConfig.starbound.binPath = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'throws if assetsPath is not set', ( done ) ->
    testConfig.starbound.assetsPath = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'throws if dataPath is not set', ( done ) ->
    testConfig.starbound.dataPath = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'throws if logFile is not set', ( done ) ->
    testConfig.starbound.logFile = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()

  it 'throws if configFile is not set', ( done ) ->
    testConfig.starbound.configFile = null
    cv = new ConfigValidator testConfig
    cv.check ( valid, errors ) ->
      valid.should.be.false
      errors.should.have.length 1
      done()




