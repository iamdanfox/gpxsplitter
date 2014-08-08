
MapBox = React.createClass
  propTypes:
    apiToken: React.PropTypes.string.isRequired
    id:       React.PropTypes.string.isRequired

  defaultProps:
    styleUrl: 'https://www.mapbox.com/mapbox-gl-styles/styles/outdoors-v4.json'

  componentDidMount: ->
    mapboxgl.accessToken = @props.apiToken

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


    map = new mapboxgl.Map
      container: @props.id
      style: mapboxStyle
      center: [37.830348, -122.486052]
      zoom: 15


    geoJSON =
      "type": "Feature",
      properties: {}
      "geometry":
        "type": "LineString",
        "coordinates":[
          [-122.48369693756104, 37.83381888486939],
          [-122.48348236083984, 37.83317489144141],
          [-122.48339653015138, 37.83270036637107],
          [-122.48356819152832, 37.832056363179625],
          [-122.48404026031496, 37.83114119107971],
          [-122.48404026031496, 37.83049717427869],
          [-122.48348236083984, 37.829920943955045],
          [-122.48356819152832, 37.82954808664175],
          [-122.48507022857666, 37.82944639795659],
          [-122.48610019683838, 37.82880236636284],
          [-122.48695850372314, 37.82931081282506],
          [-122.48700141906738, 37.83080223556934],
          [-122.48751640319824, 37.83168351665737],
          [-122.48803138732912, 37.832158048267786],
          [-122.48888969421387, 37.83297152392784],
          [-122.48987674713133, 37.83263257682617],
          [-122.49043464660643, 37.832937629287755],
          [-122.49125003814696, 37.832429207817725],
          [-122.49163627624512, 37.832564787218985],
          [-122.49223709106445, 37.83337825839438],
          [-122.49378204345702, 37.83368330777276]
        ]
    route = new mapboxgl.GeoJSONSource({ data: geoJSON })
    map.addSource('route', route)
    console.debug map

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