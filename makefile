all: ui.js mapbox.js

ui.js: ui.jsx.coffee
	cjsx-transform ui.jsx.coffee | coffee -csb > ui.js

mapbox.js: mapbox.jsx.coffee
	cjsx-transform mapbox.jsx.coffee | coffee -csb > mapbox.js
