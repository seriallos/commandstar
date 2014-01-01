{ ConfigValidator } = require './helpers/index.coffee'

goodConfig =

describe 'ConfigValidator', ->
  testConfig = null

  beforeEach ( done ) ->
    done()

  it 'verifies starbound paths are set', ( done ) ->
    cv = new ConfigValidator goodConfig
    done()
