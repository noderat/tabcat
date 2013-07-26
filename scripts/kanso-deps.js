// very simple NodeJS script that reads Makefile dependencies out of kanso.json
fs = require('fs')

fs.readFile('kanso.json', 'utf8', function(err, data) {
    if (err) {
	return console.log(err);
    }

    kanso = JSON.parse(data);

    var printDependency = function (path) {
	process.stdout.write(path);
	process.stdout.write(' ');
    };

    (kanso.attachments || []).forEach(printDependency);
    (kanso.modules || []).forEach(printDependency);
});
