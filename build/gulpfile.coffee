gulp = require 'gulp'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
stylish = require 'coffeelint-stylish'
gutil = require 'gulp-util'


parameters = require '../config/parameters.coffee'

gulp.task 'coffeelint', ->
  for name, target of parameters.targets
    for path in target.paths
      gulp.src path + '/*.coffee'
        .pipe coffeelint()
        .pipe coffeelint stylish
        .pipe coffeelint.reporter 'fail'
        .on 'error', gutil.log

gulp.task 'coffee', ->
  for name, target of parameters.targets
    for path in target.paths
      gulp.src path + '/*.coffee'
        .pipe coffee bare:true
        .pipe gulp.dest path
        .on 'error', gutil.log

gulp.task 'default', ['cofeelint', 'coffee']