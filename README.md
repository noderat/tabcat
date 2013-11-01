TabCAT
======

TabCAT (Tablet-based Cognitive Assessment Tool) is used by the [UCSF Memory and Aging Center](http://mac.ucsf.edu) to help diagnose Alzheimer's and other forms of dementia with a series of cognitive tasks, administered on an iPad or other tablet.

TabCAT is pure HTML5, so it can, in theory, run in any modern browser, and writing new tasks requires only basic web programming skills. It uses [CouchDB](http://couchdb.apache.org/) as its backend to store transcripts of tasks, which can be retrieved in JSON format.

TabCAT is designed with [HIPAA](http://www.hhs.gov/ocr/privacy/) compliance in mind. By default, it does not store any [PHI](http://www.hhs.gov/ocr/privacy/hipaa/understanding/coveredentities/De-identification/guidance.html#protected) at all, though it can be configured to store limited dataset PHI (e.g. dates) or full PHI. Any PHI is clearly tagged as such so that it can be later stripped out if need be.

TabCAT can deal with a poor or nonexistent network connection by automatically shifting into offline mode; data for tasks will be stored in the browser's local storage until the network is available again.


