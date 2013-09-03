// very simple NodeJS script that reads attachments out of kanso.json files and
// outputs a manifest file
fs = require('fs');

var out = process.stdout;

out.write('CACHE MANIFEST\n')

for (var i = 2; i < process.argv.length; i++) {
    data = fs.readFileSync(process.argv[i], 'utf8');

    var kanso = JSON.parse(data);

    // add header comment
    if (i === 2) {
        out.write('# TabCAT v');
        out.write(kanso.version);
        // if we're developing, add a nonce to the manifest
        if (/-dev/.test(kanso.version)) {
            out.write(' ');
            out.write((new Date).toISOString());
        }
        out.write('\n');
    }

    // add design document
    out.write('/tabcat/_design/' + kanso.name + '\n');
    // add attachments
    if (kanso.attachments) {
        kanso.attachments.forEach(function(path) {
            out.write(
                '/tabcat/_design/' + kanso.name + '/' + path + '\n');
        });
    }
}
