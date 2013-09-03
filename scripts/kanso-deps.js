// very simple NodeJS script that reads Makefile dependencies out of kanso.json
fs = require('fs');

data = fs.readFileSync('kanso.json', 'utf8');

var kanso = JSON.parse(data);

var printDependency = function (path) {
    process.stdout.write(path);
    process.stdout.write(' ');
};

(kanso.attachments || []).forEach(printDependency);
(kanso.modules || []).forEach(printDependency);
