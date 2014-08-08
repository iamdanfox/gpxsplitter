all: ui.js

ui.js: ui.coffee
	coffee -cb ui.coffee
	rm ui.coffee

ui.coffee: ui.jsx.coffee
	cjsx-transform ui.jsx.coffee > ui.coffee
