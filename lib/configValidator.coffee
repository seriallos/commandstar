class ConfigValidator

  constructor: ( @config ) ->
    @errors = []

  addError: ( msg ) ->
    @errors.push msg

  check: ( callback ) ->

    @checkRequiredFields()

    if @errors.length > 0
      callback false, @errors
    else
      callback true, null

  checkRequiredFields: ->
    if not @config.starbound.binPath
      @addError 'starbound.binPath must be set'
    if not @config.starbound.assetsPath
      @addError 'starbound.assetsPath must be set'
    if not @config.starbound.dataPath
      @addError 'starbound.dataPath must be set'
    if not @config.starbound.logFile
      @addError 'starbound.logFile must be set'
    if not @config.starbound.configFile
      @addError 'starbound.configFile must be set'


module.exports = ConfigValidator
