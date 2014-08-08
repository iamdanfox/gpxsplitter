
MapBox = React.createClass
  displayName: 'MapBox'

  propTypes:
    apiToken: React.PropTypes.string.isRequired
    id:       React.PropTypes.string.isRequired
    lines:    React.PropTypes.arrayOf( React.PropTypes.shape
      id: React.PropTypes.string.isRequired
      points: React.PropTypes.array.isRequired
      strokeColor: React.PropTypes.string.isRequired
      strokeWidth: React.PropTypes.number
    )

  defaultState:
    geoJSONSources: []

  defaultProps:
    styleUrl: 'https://www.mapbox.com/mapbox-gl-styles/styles/outdoors-v4.json'

  addGeoJSONSource: (line) ->
    geoJSONSource = new mapboxgl.GeoJSONSource
      data:
        type: 'Feature'
        geometry:
          type: 'LineString'
          coordinates: line.points.map (point) -> [point.longitude, point.latitude]

    @map.addSource 'route', geoJSONSource
    return geoJSONSource

  componentDidMount: ->
    mapboxgl.accessToken = @props.apiToken
    console.log 'componentDidMount'

    mapboxStyle.layers.push({
      "id": "route",
      "source": "route",
      "render": {
        "$type": "LineString",
        "line-join": "round",
        "line-cap": "round"
      },
      "style": {
        "line-color": "#FF4136",
        "line-width": 3
      },
      "type": "line"
    })

    @map = new mapboxgl.Map
      container: @props.id
      style: mapboxStyle
      center: [38.3911370, -122.4399970]
      zoom: 15


    geoJSONSource = @addGeoJSONSource @props.lines[0]

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