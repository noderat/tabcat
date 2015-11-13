gulp = require 'gulp'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
stylish = require 'coffeelint-stylish'
gutil = require 'gulp-util'
sass = require 'gulp-sass'


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

gulp.task 'express', ->
  express = require('express')
  app = express()
  app.use require('connect-livereload')(port: 35729)
  app.use express.static(__dirname)
  app.listen 4000, '0.0.0.0'
  return

tinylr = undefined
gulp.task 'livereload', ->
  tinylr = require('tiny-lr')()
  tinylr.listen 35729
  return

notifyLiveReload = (event) ->
  fileName = require('path').relative(__dirname, event.path)
  tinylr.changed body: files: [ fileName ]
  return

gulp.task 'styles', ->
  sass('sass', style: 'expanded')
    .pipe(gulp.dest('css'))
    .pipe(rename(suffix: '.min'))
    .pipe(minifycss())
    .pipe gulp.dest('css')

gulp.task 'watch', ->
  gulp.watch 'sass/*.scss', [ 'styles' ]
  gulp.watch '*.html', notifyLiveReload
  gulp.watch 'css/*.css', notifyLiveReload
  return

gulp.task 'default', ['cofeelint', 'coffee', 'express', 'livereload']