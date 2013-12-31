codeDir = "../../lib"

{StarboundServer} = require "#{codeDir}/starboundserver/server.coffee"
{ServerLog} = require "#{codeDir}/starboundserver/log.coffee"
{ServerMonitor} = require "#{codeDir}/starboundserver/monitor.coffee"
{MockServer} = require "./mockserver.coffee"
Datastore = require 'nedb'

root = exports ? this

root.StarboundServer = StarboundServer
root.ServerLog = ServerLog
root.ServerMonitor = ServerMonitor
root.MockServer = MockServer
root.Datastore = Datastore
