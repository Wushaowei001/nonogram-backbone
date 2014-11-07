var gulp = require('gulp'),
	browserify = require('gulp-browserify'),
	rename = require('gulp-rename'),
	less = require('gulp-less'),
	watch = require('gulp-watch');

gulp.task('coffee', function () {
	gulp.src('src/app.coffee', { read: false })
		.pipe(browserify({
			transform: ['coffeeify', 'jstify'],
			extensions: ['.coffee', '.html']
		}))
		.pipe(rename('app.js'))
		.pipe(gulp.dest('dist'));
});

gulp.task('less', function () {
	gulp.src('src/stylesheets/main.less')
		.pipe(less())
		.pipe(gulp.dest('dist/assets/stylesheets'));
});

gulp.task('build', function () {
	gulp.start(['coffee', 'less']);
});

gulp.task('watch', function () {
	gulp.watch(['src/**/*.coffee'], ['coffee']);
});