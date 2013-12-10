{ServerInfo} = require './classes/serverinfo.coffee'

console.log "---- Running -----"

info = new ServerInfo

info.isRunning ( status ) ->
  console.log switch
    when status == info.STATUS_UNKNOWN then "Server status unknown"
    when status == info.STATUS_UP then "Server is UP"
    when status == info.STATUS_UNKNOWN then "Server is DOWN"
    else "Unable to determine server status"
