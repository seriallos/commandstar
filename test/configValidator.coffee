{ ConfigValidator } = require './helpers/index.coffee'

testConfig =

describe 'ConfigValidator', ->
  it 'verifies starbound paths exist', ( done ) ->
    cv = new ConfigValidator testConfig
