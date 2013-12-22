fs = require 'fs'
util = require 'util'

class MockServer

  running:   null
  serverId:  null
  logFile:   null
  logHandle: null

  # Info: Client 'Seriallos' <1> (209.6.253.90:61374) connected
  LINE_PLAYER_CONNECT: "Info: Client '%s' <%s> (0.0.0.0:0) connected"

  # Info: Reaping client 'Seriallos' <4> (209.6.253.90:49294) connection
  LINE_PLAYER_DISCONNECT: "Info: Reaping client '%s' <%s> (0.0.0.0:0) "+
                          "connection"

  LINE_PLAYER_CHAT: "Info:  <%s> %s"
  LINE_SERVER_START: "Info: Done loading Star::Root"
  LINE_SERVER_STOP: "Info: Server shutdown gracefully"

  # Info: Server version 'Beta v. Offended Koala' '623' '424'
  LINE_SERVER_VERSION: "Info: Server version '%s' '1' '2'"

  LINE_SEGFAULT: "Error: Segfault Encountered!"

  configData:
    "audioChannels" : 2,
    "authHostname" : "auth.playstarbound.com",
    "audioChannelSeparation" : [ -25, 25 ],
    "clearUniverseFiles" : false,
    "musicVol" : 100,
    "checkAssetsDigest" : false,
    "rootKey" : "MIICCgKCAgEAuuxHOxa47eCix12TeI1KiDuSvu6Yculxl3yOzXDGG3OfS3A"+
                "1sUioUy5wM8YZwoI0jpiVxsyZgsFZtzbO948H/v47I6YXwfGJ0ciw0RrHfx"+
                "gPpeoTEEBOckWYJAFYWmF0xh5tN7RxMkVwFcGSFImgsA83h4xNvC9m+eiLs"+
                "741sCfs36qD5Ka0ApI2RzeruKbGDZ/lBy/E/3HfLWOituTu37WZEbkFSruc"+
                "0zu6aNAeEJB7vV4pun4BaEX7MtMzIokvGfzxRYJNlp6+T7McMAcNHQShkWx"+
                "7cVd8TPzEUe7oafmrw0EM77Ja5PIil0w0Zr3Z1ITKI+G1zGSeAvjdO6N4hM"+
                "UEthcT5H7YDuVZVb/pSPGAojIjh7lhoFZBI+2k9mOFMV+D6ysWbfScfaczR"+
                "W9W6Gs5Kt/Gqa+iLGR6P4Xa9pOfjVz/mIW1HzYjPcjXqhC4rsiur1wlkqlj"+
                "owcK5dyufb79eeULUgq9j7g2lBDkEuvzm83plrwvSKKRFToB8D4nFW01c+H"+
                "AbpNZdEW1r+J+NdV8Meoo4sB9+8wEfnQadS/eGEqNwh6CPVIXTubpzqgXiL"+
                "CowFjRQ0O9m5GjrsnC8vGbNZOxvxp/gM6uhoYEVm2QvZPFRjsBiOEWi6/Z5"+
                "YXs3fa2528JPBe/bGOb+QA8NUiyIFfPl/c4muFoR81yixkCAwEAAQ==",
    "serverPasswords" : [ "", "duckies", "swordfish" ],
    "maximizedResolution" : [ 1000, 600 ],
    "maxFrameskip" : 5,
    "pixelRatioIdx" : 3,
    "allowAdminCommands" : true,
    "allowAdminCommandsFromAnyone" : true,
    "clearPlayerFiles" : false,
    "defaultWorldCoordinate" : "alpha:-84936662:-62554636:-13754701:6:12",
    "fullscreen" : false,
    "renderPriority" : true,
    "sfxVol" : 100,
    "gamePort" : 21025,
    "controlPort" : 21026,
    "fullscreenResolution" : [ 1920, 1080 ],
    "authPort" : 21027,
    "claimFile" : "indev.claim",
    "passwordHash" : "",
    "windowTitle" : "Starbound - Beta",
    "vsync" : true,
    "renderSleep" : true,
    "waitForUpdate" : true,
    "sampleRate" : 44100,
    "renderPreSleepRemainder" : 4,
    "username" : "",
    "title.connectionString" : "",
    "crafting.filterHaveMaterials" : false,
    "speechBubbles" : true,
    "zoomLevel" : 3,
    "upnpPortForwarding" : true,
    "maximized" : true,
    "windowedResolution" : [ 1000, 600 ],
    "attemptAuthentication" : false,
    "useDefaultWorldCoordinate" : false

  constructor: ( ) ->
    @serverId = Math.floor( Math.random() * 100000 )
    @serverDir = "#{__dirname}/_mockserver/#{@serverId}"
    @logFile = "#{@serverDir}/server.log"
    @configFile = "#{@serverDir}/server.config"

  getOpts: ( ) ->
    opts =
      binPath: '/tmp'
      assetsPath: '/tmp'
      dataPath: '/tmp'
      configPath: @configFile
      logFile: @logFile
      watchInterval: 10

  start: ( ) ->
    fs.mkdirSync @serverDir
    @logHandle = fs.openSync @logFile, 'w'
    fs.writeFileSync @configFile, JSON.stringify( @configData )
    @running = true

  stop: ( ) ->
    fs.closeSync @logHandle
    @cleanup()
    @running = true

  cleanup: ( ) ->
    fs.unlinkSync @logFile
    fs.unlinkSync @configFile
    fs.rmdirSync @serverDir

  writeLine: ( line ) ->
    if not @running
      throw new Error "writeLine called while MockServer is stopped"
    fs.writeSync @logHandle, "#{line}\n"
    fs.fsync @logHandle

  logConnectPlayer: ( playerId, playerName ) ->
    msg = util.format @LINE_PLAYER_CONNECT, playerName, playerId
    @writeLine msg

  logDisconnectPlayer: ( playerId, playerName ) ->
    msg = util.format @LINE_PLAYER_DISCONNECT, playerName, playerId
    @writeLine msg

  logChat: ( who, what ) ->
    msg = util.format @LINE_PLAYER_CHAT, who, what
    @writeLine msg

  logServerStart: ( ) ->
    @writeLine @LINE_SERVER_START

  logServerStop: ( ) ->
    @writeLine @LINE_SERVER_STOP

  logServerVersion: ( version ) ->
    msg = util.format @LINE_SERVER_VERSION, version
    @writeLine msg

  logSegfault: ->
    @writeLine @LINE_SEGFAULT

exports.MockServer = MockServer
