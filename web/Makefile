COFFEE = $(shell find . -name "*.coffee" -type f)
JS = $(COFFEE:.coffee=.js)

STYL = $(shell find . -name "*.styl" -type f)
CSS = $(STYL:.styl=.css)

JADE = $(shell find . -name "*.jade" -type f)
HTML = $(JADE:.jade=.html)

all: $(HTML) $(CSS) $(JS)

%.html: %.jade
	jade -p . $<

%.css: %.styl
	stylus -I . $< --include-css

%.js: %.coffee
	coffee -cb $<

clean:
	rm -f $(HTML) $(CSS) $(JS)

.PHONY: clean