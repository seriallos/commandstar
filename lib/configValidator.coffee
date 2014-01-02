fs = require 'fs'

class ConfigValidator

  constructor: ( @config ) ->
    @errors = []

  addError: ( msg ) ->
    @errors.push msg

  check: ( callback ) ->

    @checkRequiredFields()

    if @errors.length == 0
      # only run this is required field check passes
      @checkPathsExist()

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

  checkPathsExist:  ->
    if not @pathExists @config.starbound.binPath
      @addError 'starbound.binPath does not exist'

  pathExists: ( path ) ->
    # This uses sync on purpose since config checking is so early
    try
      stat = fs.statSync path
      return true
    catch err
      return false

module.exports = ConfigValidator
