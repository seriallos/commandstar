root = exports ? this
fs = require 'fs'

{exec} = require 'child_process'

class ServerInfo

  STATUS_ERROR:   -2
  STATUS_UNKNOWN: -1
  STATUS_DOWN:     0
  STATUS_UP:       1
  STATUS_MULTIPLE: 2

  defaultOpts:
    assetsPath: "/opt/starbound/assets"
    binPath: "/opt/starbound/bin"
    dataPath: "/opt/starbound/bin/universe"

  constructor: ( opts ) ->

    if not opts
      opts = {}

    @config = {}
    @status = @STATUS_UNKNOWN
    @serverRunningIntervalId = null

    @assetsPath = opts.assetsPath ? @defaultOpts.assetsPath
    @binPath = opts.binPath ? @defaultOpts.binPath
    @dataPath = opts.dataPath ? @defaultOpts.dataPath

    @__loadServerConfig()

    @__startServerMonitor()

  __loadServerConfig: ->
    configFile = "#{@binPath}/starbound.config"
    fs.readFile configFile, 'utf8', ( err, data ) =>
      if err
        throw new Error "Unable to read config file: #{err}"
      @config = JSON.parse data

  #### Server Process Monitoring

  __startServerMonitor: ->
    @serverRunningIntervalId = setInterval( @__checkRunning, 1000 )

  __stopServerMonitor: ->
    clearInterval @serverRunningIntervalId

  # fat arrow to avoid the interval context
  __checkRunning: =>
    # fat arrow so class context is maintained in callback
    # maybe hacky
    exec 'pgrep starbound', ( error, stdout, stderr ) =>
      if error
        console.log "Error getting server PID: #{error}"
        @status = @STATUS_ERROR
      else
        origOut = stdout
        pids = stdout.replace(/^\s+|\s+$/g, '').split "\n"
        len = pids.length
        @status = switch
          when len <= 0 then @STATUS_DOWN
          when len == 1 then @STATUS_UP
          when len >= 2 then @STATUS_MULTIPLE
          else @STATUS_ERROR
        if @status == @STATUS_ERROR
          console.log "Unable to determine if server is running"
          console.log "pgrep stdout = #{stdout}"
          console.log "pgrep stderr = #{stderr}"
          console.log "pgrep error = #{error}"

root.ServerInfo = ServerInfo
