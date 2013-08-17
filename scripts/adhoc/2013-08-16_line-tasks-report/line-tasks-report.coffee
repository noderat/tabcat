csv = require('csv')
fs = require('fs')
JSONStream = require('JSONStream')

stream = fs.createReadStream(process.argv[2], encoding: 'utf8')
parser = JSONStream.parse('*.encounters.*')
csvout = csv().to(process.stdout)

parser.on('data', (encounter) ->
  for task in encounter.tasks
    if task.finishedAt
      csvout.write([
        encounter.patientCode,
        encounter.encounterNum,
        task.name
      ])
)

stream.pipe(parser)
