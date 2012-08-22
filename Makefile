all: app.js
	cd web; make

app.js: app.coffee
	coffee -cb $<

watch:
	watch -n 1 make

run: all
	vertx run app.js

.PHONY: watch run