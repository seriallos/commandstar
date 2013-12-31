commandstar
===========

Starbound Server Status Website

The best server resource for your players!

[![Build Status](https://travis-ci.org/seriallos/commandstar.png)](https://travis-ci.org/seriallos/commandstar)

Currently works for: **Angry Koala**

Visit the [Demo Server!](http://commandstar.munshot.com:8080/)

![](https://raw.github.com/seriallos/commandstar/master/commandstar.png)

Features
========

**Current**

* Real-time display of active players
* Real-time display of in-game chat
    * Relay game chat to HipChat
* Real-time server up/down status
* Active solar systems: sector, X, and Y
* Server Description
* Total worlds explored, total players ever seen
* Easy to install, easy to run
    * Tested on Win7, OS X, and Linux (Ubuntu)
* Mobile-friendly design

Also note that CommandStar plays nicely with other server tools as it runs
completely independently of the Starbound server (and server wrappers).

**Upcoming**

* "Captain's Log" - Shared notes of visited world
* User notes

Requirements
============

Tested on Ubuntu 12.04, Windows 7, and OS X Mavericks

* Starbound server
* NodeJS 0.10.x

CommandStar must run on the same host as the Starbound server as it requires
direct access to the server log files.  NFS probably won't work as it uses file
watching code that needs to be on the same filesystem.

Installation
============

This is still very early stuff!

**Ubuntu**

**Make sure you have NodeJS 0.10.x!**

You will likely need to install the latest version from the chris-lea PPA.

https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager

    git clone https://github.com/seriallos/commandstar
    cd commandstar
    npm install
    
    # make your own config file and update values
    vim config/`hostname`.yaml
    
    chmod u+x runServer.sh
    ./runServer.sh

You can also download a release tgz or ZIP and skip the github clone process.

**Windows**

* Download and Install NodeJS: http://nodejs.org/download/
* Download the latest release of CommandStar: https://github.com/seriallos/commandstar/releases/
* Extract the archive
* Edit config/default.yaml (or create config/{YOUR-MACHINENAME-HERE}.yaml)
    * Add a nice server name and description
    * Set up the starbound paths and files for your machine.
* Double click runServer.bat to start the CommandStar process
* Visit http://localhost:8080/

Configuration Files
===================

Configuration files all live in `config` and can be layered to keep things
simple.

It's best to not edit default.yaml directly as new configurations may be added
with new versions of CommandStar.  The best method is to use a hostname-specific
configuration.

When setting up CommandStar, you'll want to make a config file named after the
hostname of your machine.  To determine this hostname, do one of the following
based on your OS:

**Linux**

In a terminal, run the `hostname` command.  It will print out the
hostname of your machine.  For example:

    $ hostname
    seriallos-linux

In this example, you would create `config/seriallos-linux.yaml` and put in your
overrides.

**Windows**

Run `cmd.exe` and run the `hostname` command.  This will show the hostname of
your machine.  For example:

    C:\Users\seriallos>hostname
    seriallos-PC

In this example, you would create `config\seriallos-PC.yaml` and put in your
overrides.

**Directive Overrides**

The hostname-specific configuration file will inherit everything from
default.yaml.  In this file, you will only need to manage configurations that
you want to change.

For example, if you just want to change the server name and description, you can
make a file that only contains the following lines:

    serverName: My Starbound Server

    serverDescription: Welcome!

That's all that needs to be in your hostname-specific YAML file!

Configuration Options
=====================

**serverName**

Name to display as the title of the page.

**serverDescription**

Long description of your server.  Include whatever you want or use it as a
message of the day area.

* HTML tags supported
* An empty description will hide the Server Description panel completely.

**starbound**

Paths for assets, executables, and whatnot.

* starbound.binPath: Directory that contains the executable
* starbound.assetsPath: Starbound assets directory
* starbound.dataPath: Starbound server universe directory
* starbound.logFile: Full path to 'starbound_server.log'
* starbound.configFile: Full path to 'starbound.config'

**features**

Toggle features on and off.

* features.serverStatus: Enables a "heartbeat" check on the server port to see
  if the server is up..  Default is false
* features.activeSystems: Enables the "Active Systems" panel on the website and
  supporting APIs.  Default is true
* features.apiFooter: Enables the API links in the footer of the web page.
  Default is true

**ignoreChatPrefixes**

List of characters that should be ignored when at the start of a chat line.
Defaults to /#

* / is for all normal slash commands
* # is the admin chat channel for the server wrapper Starrybound

**listenPort**

Port that the HTTP server binds to.  Defaults to 8080.

If you want to serve this over port 80, I recommend having a real web server
like apache or nginx in front of node.  You *can* run runServer.sh as root to
use port 80 but it's not recommended.

**maxRecentChatMessages**

Number of chat messages to keep (default 100)

Setting this too high can vastly increase initial page load time and bloat
memory usage.

**serverStatus**

Configurations for the server status feature

* serverStatus.checkFrequency: How often to check the game server port, in
  seconds.  Default is 300 seconds.

**customCss**

List of custom CSS files to use on the page.

* Files must exist in public/css/
* CSS is dynamically loaded after the DOM is ready

**hipchat**

These are only used if you provide hipchat.token.  HipChat is a chat service
sort of like IRC.  You must have your own account set up at www.hipchat.com

* hipchat.token: API Token for your HipChat (default to NULL)
    * Wrap your token in double quotes
    * Requires a *version 1* token.
* hipchat.user: Username to relay in-game chat (defaults to Server)
* hipchat.room: Room to speak in (defaults to Starbound)
    * This room must *already* exist.  It will not be created automatically
* hipchat.notify: Whether to cause a notification alert or not (defaults to false)
* hipchat.color: Background color for the message (defaults to yellow)

**IRC**

Used to have CommandStar connect to an IRC channel and relay in-game chat.
This chat is **one-way**, from the game to IRC.

* irc.server: IRC host. Defaults to *empty*
* irc.nick: Nickname the bot should use. Defaults to StarboundBot
* irc.channel: Channel to connect to.  Defaults to "#starbound"
* irc.user: Username to connect to the server as.  Defaults to empty.
* irc.password: Password to use when connected.  Defaults to empty.
