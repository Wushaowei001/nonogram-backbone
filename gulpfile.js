var gulp = require('gulp'),
    browserify = require('gulp-browserify'),
    uglify = require('gulp-uglify'),
    rename = require('gulp-rename'),
    less = require('gulp-less'),
    cssmin = require('gulp-cssmin'),
    autoprefixer = require('gulp-autoprefixer'),
    watch = require('gulp-watch'),
    connect = require('gulp-connect');

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
    gulp.src('src/assets/stylesheets/main.less')
        .pipe(less())
        .pipe(autoprefixer({
            browsers: ['last 2 versions'],
            cascade: false
        }))
        .pipe(cssmin())
        .pipe(rename({ suffix: '.min' }))
        .pipe(gulp.dest('dist/assets/stylesheets'));
});

gulp.task('copy-assets', function () {
    var assetSources = [
        'src/assets/fonts/**',
        'src/assets/images/**',
        'src/assets/music/**',
        'src/assets/sounds/**'
    ];
    gulp.src(assetSources, { base: './src' })
        .pipe(gulp.dest('dist'));

    gulp.src('src/assets/index.html', { base: './src/assets' })
        .pipe(gulp.dest('dist'));
});

gulp.task('build', function () {
    gulp.start(['coffee', 'less', 'copy-assets', 'reload']);
});

gulp.task('watch', function () {
    gulp.watch([
        'src/**/*.coffee',
        'src/**/*.html',
        'src/assets/stylesheets/*.less'], ['build']);
});

gulp.task('cordova', function () {
    gulp.src(['dist/javascript/**', 'dist/assets/**'], { base: './dist' })
        .pipe(gulp.dest('cordova/www'));
});

gulp.task('watch-cordova', function () {
   gulp.watch([
    'src/**/*.coffee',
    'src/**/*.html',
    'src/stylesheets/main.less'], ['build', 'cordova']);
});

gulp.task('connect', function () {
    connect.server({
        root: 'dist',
        livereload: true
    });
});

gulp.task('reload', function () {
    connect.reload();
});

gulp.task('default', ['connect', 'watch']);
