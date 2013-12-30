{Buffer} = require 'buffer'
dgram = require 'dgram'

###
createRequest = ( type, id, body ) ->
  size = Buffer.byteLength( body ) + 14
  buffer = new Buffer size

  buffer.writeInt32LE( size - 4, 0 )
  buffer.writeInt32LE( id,       4 )
  buffer.writeInt32LE( type,     8 )
  buffer.write( body, 12, size - 2, 'ascii' )
  buffer.writeInt16LE( 0, size - 2 )

  return buffer

readResponse = ( buffer ) ->
  response =
    size: buffer.readInt32LE( 0 )
    id:   buffer.readInt32LE( 4 )
    type: buffer.readInt32LE( 8 )
    body: buffer.toString( 'ascii', 12, buffer.length - 2 )

  return response
###

a2s_info_req = ->
  header = 0xFF + 0xFF + 0xFF + 0xFF + 0x54
  body = "Source Engine Query\0"

  size = Buffer.byteLength( body ) + 5

  buf = new Buffer size

  buf.writeInt16LE 0xFF, 0
  buf.writeInt16LE 0xFF, 1
  buf.writeInt16LE 0xFF, 2
  buf.writeInt16LE 0xFF, 3
  buf.writeInt16LE 0x54, 4
  buf.write body, 5

  console.log buf.toString()

  return buf

host = 'commandstar.munshot.com'
port = 21025

client = dgram.createSocket 'udp4'

client.on 'message', ( data, rinfo ) ->
  console.log 'MESSAGE'
  console.log data.toString()
  console.log rinfo

client.on 'error', ( err ) ->
  console.log 'ERROR'
  console.log err

client.on 'close', ->
  console.log "CLOSE"

client.bind 0, ->
  console.log "LISTENING"
  address = client.address()
  console.log "Listening on #{address.address}:#{address.port}"

  req = a2s_info_req()

  console.log req

  client.send req, 0, req.length, port, host, ( err, bytes ) ->
    if err
      console.log err
    else
      console.log "Request sent"

