CHANGELOG
=========

0.1.6
-----

This may be another unstable release.  NeDB is a brand new dependency that I've
only been able to test on my own low-pop servers.

Note: Server status should be usable soon as the socket leak has been fixed for
the next Starbound release.  [Forum link][socket-leak-fix-forum]

[socket-leak-fix-forum]: http://community.playstarbound.com/index.php?threads/crash-bug-unreleased-socket-files-too-many-open-files.54833/page-2#post-1624126

**New**

* Show total worlds explored and total players seen (ever) on the server.
    * These will only start tracking with this new update.
    * Players are tracked by their game name.
* Adds several API endpoints
    * /server/worlds - Returns info on all visited worlds
    * /server/players - Returns info on all players ever seen

**Fixes/Tweaks**

* runServer.sh should now work from any path (Fixes #11)
* Fixes bug where slash chat was showing up on the site

**Technical**

* Adds NeDB as a dependency to have a bit of persistence when restarted
    * Default data path is ./data.  This is configurable.
    * This will enable moving forward on a bunch of other features.
    * Using a pure NodeJS library keeps CommandStar easy to install and run.

0.1.5
-----

This release has a ton of internal changes.  It's very possible that I've broken
some things that used to work.

**New**

* Server status check is available but defaults OFF
    * This is due to a socket file descriptor leak in the starbound server code.
      If you use this feature, be aware that it will eventually cause the
      server to crash once the server has reached the open file limit.
    * More info, discussion, and a possible fix on the starbound forums:
      http://community.playstarbound.com/index.php?threads/crash-bug-unreleased-socket-files-too-many-open-files.54833/
* Ignores chat lines that start with # (Starlight admin prefix)

**Fixes/Tweaks**

* Player list and world list should clear out when server restarts
* All colors codes should be filtered out.  For example, ^#cyan;
* Reading old chat is easier now.  You won't get bounced to new messages when
  they show up. (Thanks to **malobre** for initial code!)
* Fixes bug where active systems would disappear on change

**Technical**

* Major codebase refactor
    * starboundserver/server.coffee manages the log watcher and network monitor
    * Moved a bunch of files/dirs around for better organization
        * server.coffee is now lib/commandstar.coffee
        * classes/ is now lib/
* Bunch more tests

0.1.4
-----

**New**

* Relay in-game chat to IRC. See config/default.yaml for details on configuring
* Configuration flag to enable/disable active systems display
* Configuration flag to enable/disable the API list in the footer
* /server/players API endpoint (thanks https://github.com/malobre !)
    * Alias: /server/playerList
* Detect crashes caused by segfaults

**Fixes/Tweaks**

* Player list is sorted by name
* Reduced logging from server.coffee
* Player names surrounded by &lt;brackets&gt; in chat log
* Properly remove multiple color codes in player names and chat messages
* Tweaks to default player list and system list (thanks **malobre**!)

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


