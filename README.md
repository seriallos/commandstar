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

This is super duper alpha and really only intended for nodejs hackers /
knowledgable sysadmins.

It's super rough.

    git clone https://github.com/seriallos/commandstar
    cd commandstar
    npm install
    coffee server.coffee
