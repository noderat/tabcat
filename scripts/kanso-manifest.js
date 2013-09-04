// very simple NodeJS script that reads attachments out of kanso.json files and
// outputs a manifest file
fs = require('fs');
path = require('path');

var out = process.stdout;

out.write('CACHE MANIFEST\n')

for (var i = 2; i < process.argv.length; i++) {
    var kansoPath = process.argv[i]
    var kanso = JSON.parse(fs.readFileSync(kansoPath, 'utf8'));

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
        var dirname = path.dirname(kansoPath)
        kanso.attachments.forEach(function(subPath) {
            // only allow files, not directories
            fullPath = path.join(dirname, subPath)
            if (!fs.existsSync(fullPath)) {
                process.stderr.write(
                    fullPath + '(from ' + kansoPath + ') does not exist!\n')
                process.exit(1)
            } else if (!fs.statSync(fullPath).isFile()) {
                process.stderr.write('"attachments" in ' + kansoPath +
                                     ' must only include files (' +
                                     fullPath + ' is a directory)\n');
                process.exit(1);
            }

            out.write(
                '/tabcat/_design/' + kanso.name + '/' + subPath + '\n');
        });
    }
}
