{EventEmitter} = require 'events'
fs = require 'fs'
# TODO: Better way to get up to node modules
jParser = require '../../node_modules/binary-format/src/jparser.js'
chokidar = require 'chokidar'
starClientContext = require './clientcontext_template.coffee'

class ClientContext extends EventEmitter

  constructor: ( opts ) ->
    if not opts
      throw new Error "ClientContext requires options"
    if not opts.dataPath
      throw new Error "ClientContext requires dataPath in constructor options"

    @dataPath = opts.dataPath
    @watcher = null

  init: ( next ) ->
    fs.readdir @dataPath, (err, files) =>
      for file in files when file.match /\.clientcontext$/
        ccFile = @dataPath + file
        @loadFile ccFile, ( uuid, data ) =>
          @emit "contextInitial", uuid, data

    @watcher = chokidar.watch(@dataPath, { persistent: true })
    @watcher
      .on('change', (path) =>
        @loadFile path, ( uuid, data ) =>
          @emit "contextChange", uuid, data)
      .on('add', (path) =>
        @loadFile path, ( uuid, data ) =>
          @emit "contextInitial", uuid, data)

  # expects full path
  loadFile: ( file, next ) ->
    if file.match /\.clientcontext$/
      clientUUID = file.replace(".clientcontext","")
      fs.readFile file, (err, data) =>
        next clientUUID, @parseData data

  parseData: ( data ) ->
    view = new jDataView(data, undefined, undefined, false)
    parser = new jParser(view, starClientContext).parse('context')

module.exports = ClientContext
