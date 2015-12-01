var gulp = require('gulp');
var sass = require('gulp-sass');
var del = require('del');
var plumber = require('gulp-plumber');
var size = require('gulp-size');
var coffee = require('gulp-coffee');
var gutil = require('gulp-util');
var sourcemaps = require('gulp-sourcemaps');

gulp.task('clean', function() {
  return del([
    '!**/*.coffee',
    '!**/*.{scss,sass}',
    'console/{css,packages,js/**/*.js}',
    'core/js/{couchdb,tabcat}/**/*.js',
    'core/packages/',
    'task-defaults/**/*.js',
    'tasks/**/js/*.js',
    'tasks/**/scoring/{packages,*.js,*.json}',
    '**/design.json',
    '**/.pushed-*',
    'config/*'
  ]);
});

gulp.task('sass', function() {
  return gulp.src(['console/scss/**/*.{scss,sass}'])
    .pipe(plumber())
    .pipe(sourcemaps.init())
    .pipe(sass().on('error', sass.logError))
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('console/css/'))
    .pipe(size({showFiles: true, title: 'SASS -> CSS:'}));
});

gulp.task('coffee', function() {
  return gulp.src(['**/*.coffee', '!node_modules/**'])
    .pipe(plumber())
    .pipe(sourcemaps.init())
    .pipe(coffee().on('error', gutil.log))
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('.'))
    .pipe(size({showFiles: true, title: 'COFFEE -> JS:'}));
});
