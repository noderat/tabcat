TabCAT
======

TabCAT (Tablet-based Cognitive Assessment Tool) is used by the [UCSF Memory and Aging Center](http://mac.ucsf.edu) to help diagnose Alzheimer's and other forms of dementia with a series of cognitive tasks, administered on an iPad or other tablet.

TabCAT is pure HTML5, so it can, in theory, run in any modern browser, and writing new tasks requires only basic web programming skills. It uses [CouchDB](http://couchdb.apache.org/) as both its web server and its backend to store transcripts of tasks, which can be retrieved in JSON format.

TabCAT is designed with [HIPAA](http://www.hhs.gov/ocr/privacy/) compliance in mind. By default, it does not store any [PHI](http://www.hhs.gov/ocr/privacy/hipaa/understanding/coveredentities/De-identification/guidance.html#protected) at all, though it can be configured to store limited dataset PHI (e.g. dates) or full PHI. Any PHI is clearly tagged as such so that it can be later stripped out if need be.

TabCAT can deal with a poor or nonexistent network connection by automatically shifting into offline mode; data for tasks will be stored in the browser's local storage until the network is available again.

Installation
------------

### Dependencies

On the server side, TabCAT requires CouchDB ([installation instructions](http://docs.couchdb.org/en/latest/install/index.html)). We have been running on version 1.3.0, but anything later than 1.2.0 should work.

If you don't want to host a server, [Iris Couch](http://www.iriscouch.com/) is a good, free option.

In order to build and install TabCAT, you will need:

 * [node.js](http://nodejs.org/)
 * [kanso](http://kan.so)
 * [CoffeeScript](http://coffeescript.org/)
 * [GNU make](http://www.gnu.org/software/make/)
 
Don't panic! Once you have node.js, installing kanso and coffeescript is just a matter of running `npm`.

If you are on a UNIX system, you probably have `make` already.

On Mac OS X, it's available as part of [XCode](https://developer.apple.com/xcode/); once you have XCode installed, install Command Line Tools from the Components tab of the Downloads preferences panel.

On Windows, you'll probably want to install [Cygwin](http://www.cygwin.com/).

Finally, if you want to get involved in developing TabCAT, we recommend installing coffeelint (`sudo npm install -g coffeelint`).

### Setting up your server

We're [working on automating this](https://github.com/UCSFMemoryAndAging/tabcat/issues/25), but until then, you'll need to do this from [Futon](http://wiki.apache.org/couchdb/Getting_started_with_Futon).

Open up Futon by browsing to `/_utils` on your server.

Click on the Configuration link on the left. Under the `couch_httpd_auth` section, set `allow_persistent_cookies` to `true` and `timeout` to `3600`. Under the `uuids` section, set `algorithm` to `random`.

Create an admin user whose username is your email address (all lowercase). (Look for the link in the lower-right corner of Futon.)

Then, sign out, and sign up a user named `tabcat` (again, lower-right corner).

Then sign back in as your admin user and create a database named `tabcat`. Click on that database, go to "Security" (upper part of the screen) and under the Admins section set the Names of admins to `["tabcat"]`.

Do the same thing with a database named `tabcat-data`. On the security screen, set the admin's names to `["tabcat"]` as before, and under the Members section, set the Roles to `["tabcat-data"]`.

(If you're on Iris Couch, you're done, go on to the next section.)

It's probably a good idea to force users to access your server via SSL; see [How to Enable SSL](http://wiki.apache.org/couchdb/How_to_enable_SSL) for further instructions.

Oh, and to allow access to your server from other hosts, you'll want to go to the `httpd` section of the "Configuration" page and set `bind_address` to `0.0.0.0`. (You don't need to do this if you're just testing/developing.)

### Adding additional users

New users will have to click the "Sign Up" link in Futon, using their (lowercase) email address as their username. Once they've signed up, enable their account by going to their user record in the `_users` database, and setting their `roles` field to `["tabcat-data"]`.

### Installing TabCAT

`cd` to the root of the source directory.

Set the environment variable `TABCAT_HOST` to your web server's URL, with the `tabcat` user's credentials. That will look something like this:

`export TABCAT_HOST=http://tabcat:your-password@localhost:5984`

Then run `make`.

### Using TabCAT

To access TabCAT, browse to `/tabcat/_design/core/login.html` on your server.

If you're on a iPad, click "Add to Home Screen" under the bookmarks menu (upper left), hit the home button, and re-launch the browser from the shortcut you just created. This launches TabCAT in Standalone mode (no nav bar), which is what you want for running tasks.

Then log in with your email and password. It'll prompt you for a patient code; if you're just testing things out, we recommend you use the patient code `0`.

If you're on Android, the best way to get the same kind of "standalone" behavior is to install [Firefox for Android](https://play.google.com/store/apps/details?id=org.mozilla.firefox). Add TabCAT to your home screen by clicking on the nav bar, the History tab, holding down on the entry for TabCAT (which should be at the top), and then choosing Add to Home Screen. Then, from Firefox, install [Full Screen mobile extension](https://addons.mozilla.org/En-us/mobile/addon/full-screen-252573/) and enable it from the Menu button.

If you're on a Microsoft Surface, your best bet is to launch TabCAT from the desktop in Internet Explore, and then enable Full Screen mode (F11, I think?).




