Things I can possibly do

* Decompose server.coffee
    * Tests for server state maintenance
    * Tests for REST endpoints
* Persist state to local JSON files to handle restarts
* Chat colors?  Either hide them or use them
* UUID location from clientcontext files
* Rewrite spaghetti jQuery frontend using Angular/Ember/etc
* Captain's Log
* User notes
* Paging for chat log API (server/chat).  Gets REAL big otherwise
* upstart / init.d scripts
* modPath, display mods running on the server using standard format
* Watch config file for changes, emit changes to frontend
* Config validation
* Error reports back to the mothership
  * Opt-in
  * Collect errors, non-private configurations, etc
* Adapter system for notifications
    * Don't want to load hipchat/IRC for admins not using them

Things when tech exists

* Send chat into the game from web / hipchat / IRC
