gulp         = require 'gulp'
sort         = require 'sort-stream'
sequence     = require 'run-sequence'
coffee       = require 'gulp-coffee'
sass         = require 'gulp-sass'
uglify       = require 'gulp-uglify'
concat       = require 'gulp-concat'
rename       = require 'gulp-rename'
del          = require 'del'
sourcemaps   = require 'gulp-sourcemaps'
autoprefixer = require 'gulp-autoprefixer'
plumber      = require 'gulp-plumber'

# Paths that we'll need for various tasks
paths =
  sass:
    input:  'src/assets/sass/**/*.scss'
    output: 'public/assets/css'
  coffee:
    input:  'src/assets/coffeescript/**/*.coffee'
    output: 'public/assets/js'
  clean: 'public/assets/{js,css}/*.map'

# Helper for sorting CoffeeScript files into one file
coffeePriorityPattern = /\/app\.coffee/i
prioritizeStream = (a, b) ->
  aRank = if a.path.match(coffeePriorityPattern) then 0 else 1
  bRank = if b.path.match(coffeePriorityPattern) then 0 else 1
  return aRank - bRank

# Task for transpiling and concatenating Sass files
gulp.task 'sass', ->
  gulp.src paths.sass.input
      .pipe plumber()
      .pipe sourcemaps.init()
      .pipe sass(outputStyle: 'compressed')
      .pipe autoprefixer('last 15 version')
      .pipe concat('style.min.css')
      .pipe sourcemaps.write('.')
      .pipe gulp.dest(paths.sass.output)

# Task for transpiling and concatenating CoffeeScript files
gulp.task 'coffee', ->
  gulp.src paths.coffee.input
      .pipe plumber()
      .pipe sort(prioritizeStream)
      .pipe sourcemaps.init()
      .pipe coffee()
      .pipe concat('app.min.js')
      .pipe uglify()
      .pipe sourcemaps.write('.')
      .pipe gulp.dest(paths.coffee.output)

# Removes dev-only files like *.map files
gulp.task 'remove-dev', (cb) -> del [paths.clean], cb

# Task for watching changes
gulp.task 'watch', ['build-dev'], ->
  gulp.watch paths.sass.input,   ['sass']
  gulp.watch paths.coffee.input, ['coffee']

# Shortcut tasks
gulp.task 'build-dev', ['sass', 'coffee']
gulp.task 'build',     (cb) -> sequence 'build-dev', 'remove-dev', cb
gulp.task 'default',   ['build']
