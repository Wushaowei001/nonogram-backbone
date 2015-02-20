var gulp = require('gulp'),
    browserify = require('gulp-browserify'),
    uglify = require('gulp-uglify'),
    rename = require('gulp-rename'),
    less = require('gulp-less'),
    cssmin = require('gulp-cssmin'),
    autoprefixer = require('gulp-autoprefixer'),
    watch = require('gulp-watch');

gulp.task('coffee', function () {
    gulp.src('src/app.coffee', { read: false })
        .pipe(browserify({
            transform: ['coffeeify', 'jstify'],
            extensions: ['.coffee', '.html'],
            debug: true // source maps
        }))
        // .pipe(uglify())
        .pipe(rename('nonogram-madness.js'))
        .pipe(gulp.dest('dist/javascript'));
});

gulp.task('less', function () {
    gulp.src('src/stylesheets/main.less')
        .pipe(less())
        .pipe(autoprefixer({
            browsers: ['last 2 versions'],
            cascade: false
        }))
        .pipe(cssmin())
        .pipe(rename({ suffix: '.min' }))
        .pipe(gulp.dest('dist/assets/stylesheets'));
});

gulp.task('build', function () {
    gulp.start(['coffee', 'less']);
});

gulp.task('copy', function () {
    gulp.src(['dist/javascript/**', 'dist/assets/**'], { base: './dist' })
        .pipe(gulp.dest('cordova/www'));
});

gulp.task('watch', function () {
    gulp.watch(['src/**/*.coffee', 'src/**/*.html'], ['coffee']);
    gulp.watch(['src/stylesheets/main.less'], ['less']);
});

gulp.task('cordova', function () {
   gulp.watch([
    'src/**/*.coffee',
    'src/**/*.html',
    'src/stylesheets/main.less'], ['build', 'copy']);
});
