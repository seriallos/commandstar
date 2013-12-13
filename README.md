commandstar
===========

Starbound Server Manager

Features
========

**Current**

* Real-time display of active players
* Real-time display of in-game chat
* Real-time server up/down status

**Upcoming**

* Coordinates of visited worlds
* Shared notes of visited world (Captain's Log)
* User notes
* Out-of-game chat / lightweight discussion

Requirements
============

Only tested on Ubuntu 12.04 64-bit so far.  Out of the box it will not support
Windows or OS X.

* Starbound server
* NodeJS 0.10.x
    * Coffeescript 1.6.3

Installation
============

**This is super duper alpha and really only intended for nodejs hackers /
knowledgable sysadmins.**

It's super rough.

    git clone https://github.com/seriallos/commandstar
    cd commandstar
    npm install
    coffee server.coffee

Configuration
=============

**listenPort**

Port that the HTTP server binds to.  Defaults to 8080.

If you want to serve this over port 80, I recommend having a real web server
like apache or nginx in front of node.  You *can* run server.coffee as root to
use port 80 but it's not recommended.

**starbound**

Paths for assets, executables, and whatnot.

starbound.binPath: Directory that contains the executable

starbound.assetsPath: Starbound assets directory

starbound.dataPath: Starbound server universe directory

starbound.logFile: Full path to 'starbound_server.log'

**hipchat**

These are only used if you provide hipchat.token

hipchat.token: API Token for your HipChat (default to NULL)
hipchat.user: Username to relay in-game chat (defaults to Server)
hipchat.room: Room to speak in (defaults to Starbound)
hipchat.notify: Whether to cause a notification alert or not (defaults to false)
hipchat.color: Background color for the message (defaults to yellow)
