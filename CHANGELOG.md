CHANGELOG
=========

0.1.4 - In Progress
-----

**New**

* Relay in-game chat to IRC. See config/default.yaml for details on configuring
* Configuration flag to enable/disable active systems display
* Configuration flag to enable/disable the API list in the footer
* /server/players API endpoint (thanks https://github.com/malobre !)
    * Alias: /server/playerList

**Fixes/Tweaks**

* Player list is sorted by name
* Reduced logging from server.coffee
* Player names surrounded by <brackets> in chat log
* Properly remove multiple color codes in player names and chat messages
* Tweaks to default player list and system list (thanks *malobre*!)

**Technical**

* No longer install testing dependencies by default


0.1.3
-----

**New**

* Configurable server description
* Display max number of players
* Display Open/Password Protected server status
* Configurable Custom CSS support

**Fixes/Tweaks**

* Slash commands are ignored
* Chat color tokens are ignored
* Long player names no longer break layout
* Various chat display tweaks (table style, HTML encoding, etc)
* Configurable number of chat messages to retain
  * Fixes long initial page load and memory issues

**Technical**

* Project passes coffeelint
* doTests.sh script to easily run all tests

0.1.2
-----

**New**

* Added "Active Systems" display
    * Will show solar system coordinates that players are visiting
    * Known Issues:
        * Sometimes the server keeps systems open when there aren't players
          on it.
        * Cannot currently determine *which* players are in which system.
        * Systems can be "active" for 30 seconds after a player leaves.

**Fixes/Tweaks**

* Show 50 chat messages on page load instead of 20
* One script to run the server for both Linux and Windows
    * Also keeps dependencies up-to-date
* Fixed chat scroll bug when there were lots of messages
* Player list now scrolls when it becomes too big
* Minor tweaks to display (padding and things like that)

**Technical**

* Removed dependency on global coffee-script
* Removed dependency on global mocha for testing
* Removed in-line styles, moved into public/css/commandstar.css

Previously, on CommandStar
--------------------------

I didn't take as good notes.  So maybe I'll fill this out later based on commit
messages.


