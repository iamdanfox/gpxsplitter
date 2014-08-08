
MapBox = React.createClass
  propTypes:
    apiToken: React.PropTypes.string.isRequired
    id:       React.PropTypes.string.isRequired

  defaultProps:
    styleUrl: 'https://www.mapbox.com/mapbox-gl-styles/styles/outdoors-v4.json'

  componentDidMount: ->
    mapboxgl.accessToken = @props.apiToken

    m = new mapboxgl.Map
      container: @props.id
      style: @props.styleUrl
      center: [40, -74.50]
      zoom: 9
    console.debug m

  shouldComponentUpdate: (nextProps, nextState) ->
    console.log 'shouldComponentUpdate'
    return false

  render: ->
    <div style={height: @props.height, width: @props.width, position: 'relative'} id={@props.id}></div>











# MapBoxInjected = React.createClass
#   getInitialState: ->
#     mapboxgl: null

#   statics:
#     MAPBOX_URL: 'https://api.tiles.mapbox.com/mapbox-gl-js/v0.2.0/mapbox-gl.js'

#   componentDidMount: ->
#     if not @state.mapboxgl? and window.mapboxgl?
#       @setState mapboxgl: window.mapboxgl
#     else
#       @injectMapBox()

#   injectMapBox: ->
#     script = document.createElement 'script'
#     script.type = 'text/javascript'
#     script.async = true
#     script.onload = =>
#       @setState mapboxgl: window.mapboxgl
#     script.src = MapBox.MAPBOX_URL
#     document.getElementsByTagName('head')[0].appendChild script

#   render: ->
#     <div>MapBox goes here</div>
