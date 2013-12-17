commandstar
===========

Starbound Server Manager

[![Build Status](https://travis-ci.org/seriallos/commandstar.png)](https://travis-ci.org/seriallos/commandstar)

Currently works for: **Offended Koala**

![](https://raw.github.com/seriallos/commandstar/master/commandstar.png)

Features
========

**Current**

* Real-time display of active players
* Real-time display of in-game chat
    * Relay game chat to HipChat
* Real-time server up/down status

**Upcoming**

* Coordinates of visited worlds
* Shared notes of visited world (Captain's Log)
* User notes
* Out-of-game chat / lightweight discussion

Requirements
============

Tested on Ubuntu 12.04 and Windows 7

* Starbound server
* NodeJS 0.10.x
    * Coffeescript 1.6.3

Installation
============

This is still very early stuff!

**Ubuntu**

    git clone https://github.com/seriallos/commandstar
    cd commandstar
    npm install
    # make your own config file
    touch config/`hostname`.yaml
    chmod u+x runServer.sh
    ./runServer.sh

You can also download a release tgz or ZIP and skip the github clone process.

**Windows**

* Download and Install NodeJS: http://nodejs.org/download/
* Download the latest release of CommandStar: https://github.com/seriallos/commandstar/releases/
* Extract the archive
* Double click setup.bat once to install dependency libraries
* Edit config/default.yaml
    * Add a nice server name
    * Set up the starbound paths and files for your machine.
* Double click runServer.bat to start the CommandStar process
* Visit http://localhost:8080/

Configuration
=============

**serverName**

Name to display as the title of the page.

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

starbound.configFile: Full path to 'starbound.config'

**hipchat**

These are only used if you provide hipchat.token.  HipChat is a chat service
sort of like IRC.  You must have your own account set up at www.hipchat.com

hipchat.token: API Token for your HipChat (default to NULL) *Wrap your token in
double quotes*
hipchat.user: Username to relay in-game chat (defaults to Server)
hipchat.room: Room to speak in (defaults to Starbound)
hipchat.notify: Whether to cause a notification alert or not (defaults to false)
hipchat.color: Background color for the message (defaults to yellow)
