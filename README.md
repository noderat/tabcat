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
 * [UglifyJS](https://github.com/mishoo/UglifyJS2)
 * [curl](http://curl.haxx.se/download.html)
 * [GNU make](http://www.gnu.org/software/make/)

Don't panic! Once you have node.js, installing kanso, coffeescript, and UglifyJS is just a matter of running:

```sh
sudo npm install -g kanso coffee-script uglify-js
```

If you are on a UNIX system, you probably have `make` (and `curl`) already.

On Mac OS X, `make` is available as part of [XCode](https://developer.apple.com/xcode/); once you have XCode installed, install Command Line Tools from the Components tab of the Downloads preferences panel.

On Windows, you'll probably want to install [Cygwin](http://www.cygwin.com/).

Finally, if you want to get involved in developing TabCAT, we recommend installing coffeelint (`sudo npm install -g coffeelint`).

### Setting up your server

The `setup_couchdb.sh` script will perform most of the setup needed for Couch DB.

```sh
export COUCHDB_URL=<COUCHDB-URL>
./setup_couchdb.sh
```

* Under the `couch_httpd_auth` section, sets `allow_persistent_cookies` to `true` and `timeout` to `3600`.
* Under the `uuids` section, sets `algorithm` to `random`.
* Creates an admin user whose username is read from the user.
* Creates a `tabcat` user with a password read from the user. This password is also stored in the `.tabcat_password` file.
* Creates a database named `tabcat`. Adds the `tabcat` user to the admins list. Adds a user provided email to members list.
* Creates a database named `tabcat-data`. Adds the `tabcat` user to the admins list. Adds a user provided email to members list.
* Under the `httpd` section, sets `bind_address` to `0.0.0.0`, so as to allow access to your server from other hosts.

You can also perform these operations from [Futon](http://wiki.apache.org/couchdb/Getting_started_with_Futon).

It's probably a good idea to force users to access your server via SSL; see [How to Enable SSL](http://wiki.apache.org/couchdb/How_to_enable_SSL) for further instructions.

### Adding additional users

New users will have to click the "Sign Up" link in Futon, using their (lowercase) email address as their username. Once they've signed up, enable their account by going to the `tabcat-data` database, clicking on Security, and adding their email to the Names section of members, just like you did with your own email: `["new.user@somewhere.com", "your.email@somewhere.com"]`.

### Installing TabCAT

`cd` to the root of the source directory.

Set the environment variable `TABCAT_HOST` to your web server's URL, with the `tabcat` user's credentials. That will look something like this:

`export TABCAT_HOST=http://tabcat:your-password@localhost:5984`

Then run `make`.

### Using TabCAT

To access TabCAT, browse to `/tabcat/_design/console/login.html` on your server.

If you're on a iPad, click "Add to Home Screen" under the bookmarks menu (upper left), hit the home button, and re-launch the browser from the shortcut you just created. This launches TabCAT in Standalone mode (no nav bar), which is what you want for running tasks.

Then log in with your email and password. It'll prompt you for a patient code; if you're just testing things out, we recommend you use the patient code `0`.

If you're on Android, the best way to get the same kind of "standalone" behavior is to install [Firefox for Android](https://play.google.com/store/apps/details?id=org.mozilla.firefox). Add TabCAT to your home screen by clicking on the nav bar, the History tab, holding down on the entry for TabCAT (which should be at the top), and then choosing Add to Home Screen. Then, from Firefox, install [Full Screen mobile extension](https://addons.mozilla.org/En-us/mobile/addon/full-screen-252573/) and enable it from the Menu button.

If you're on a Microsoft Surface, your best bet is to launch TabCAT from the desktop in Internet Explore, and then enable Full Screen mode (F11, I think?).
