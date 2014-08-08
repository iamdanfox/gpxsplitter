
MapBox = React.createClass
  getInitialState: ->
    mapboxgl: null

  statics:
    MAPBOX_URL: 'https://api.tiles.mapbox.com/mapbox-gl-js/v0.2.0/mapbox-gl.js'

  componentDidMount: ->
    if not @state.mapboxgl? and window.mapboxgl?
      @setState mapboxgl: window.mapboxgl
    else
      @injectMapBox()

  injectMapBox: ->
    script = document.createElement 'script'
    script.type = 'text/javascript'
    script.async = true
    script.onload = =>
      @setState mapboxgl: window.mapboxgl
    script.src = MapBox.MAPBOX_URL
    document.getElementsByTagName('head')[0].appendChild script

  render: ->
    <div>MapBox goes here</div>
