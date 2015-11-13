gulp = require 'gulp'
watch = require 'gulp-watch'
batch = require 'gulp-batch'
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
  app.use '/public' , express.static('public')
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
  #gulp.watch 'sass/*.scss', [ 'styles' ]
  gulp.watch 'console/*.html', usePolling: true, gulp.series 'console'
  #watch 'console/*.html', -> gulp.start

  #gulp.watch 'core/*.html', ['core']
  #gulp.watch 'public/**/*.html', notifyLiveReload
  #watch 'public/**/*.html', notifyLiveReload
  #gulp.watch 'css/*.css', notifyLiveReload
  return

gulp.task 'consoleStream', ->
  gulp.src('console/*.html')
    .pipe(watch('console/*.css'))
    .pipe(gulp.dest('public/console'));

gulp.task 'watchConsole', (callback) ->
  console.log 'watching console'
  watch 'console/**/*.html', ->
    console.log 'console changed'
    #gulp.start 'console', callback

gulp.task 'console', ->
  console.log 'console task'
  gulp.src 'console/*.html'
    .pipe(gulp.dest('public/console'))

gulp.task 'default', gulp.parallel 'watch'