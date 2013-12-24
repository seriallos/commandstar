codeDir = "../../lib"

{ServerInfo} = require "#{codeDir}/starboundserver/server.coffee"
{ServerLog} = require "#{codeDir}/starboundserver/log.coffee"
{ServerMonitor} = require "#{codeDir}/starboundserver/monitor.coffee"
{MockServer} = require "./mockserver.coffee"

root = exports ? this

root.ServerInfo = ServerInfo
root.ServerLog = ServerLog
root.ServerMonitor = ServerMonitor
root.MockServer = MockServer
