App = React.createClass
  getInitialState: ->
    xml:          null
    cutoff:       null

  updateCutoff: (newCutoff) ->
    @setState(cutoff:newCutoff)

  updateXML: (xml) ->
    @setState(xml:xml)

  render: ->
    <div className='app'>
      <h1>GPX Splitter</h1>
      { if @state.xml?
          <GPXView xml={@state.xml} cutoff={@state.cutoff} updateXML={@updateXML} updateCutoff={@updateCutoff} />
        else
          <div>
            <FileInput xml={@state.xml} cutoff={@state.cutoff} updateXML={@updateXML} updateCutoff={@updateCutoff} />
            <Blurb />
          </div> }
      { if @state.cutoff?
          <DownloadLinks xml={@state.xml} cutoff={@state.cutoff} updateXML={@updateXML} updateCutoff={@updateCutoff} /> }
      <Footer />
    </div>


FileInput = React.createClass
  getInitialState: ->
    over: false

  handleFile: (e) ->
    e.preventDefault()
    reader = new FileReader()
    reader.onload = (evt) =>
      parser = new DOMParser()
      xml = parser.parseFromString evt.target.result, 'text/xml'
      @props.updateXML xml
    files = e.target.files or e.dataTransfer.files
    reader.readAsText files[0]

  timeout: null

  handleOver: (e)->
    e.preventDefault()
    if not @state.over
      @setState over: true
    clearTimeout @timeout
    @timeout = setTimeout (=> @setState over: false), 200

  componentWillUnmount: ->
    clearTimeout @timeout

  render: ->
    <div className={if @state.over then 'fileInput over' else 'fileInput'} onDrop={@handleFile} onDragOver={@handleOver}>
      <p>Drag and drop a .gpx file</p>
      <p>or choose from your computer <input type='file' ref='inp' onChange={@handleFile}/></p>
    </div>


GPXView = React.createClass
  getInitialState: ->
    dividerX: 300

  render: ->
    # pre-process data
    @start = Date.parse @props.xml.querySelector('trkseg trkpt:first-child time').innerHTML
    @end = Date.parse @props.xml.querySelector('trkseg trkpt:last-child time').innerHTML
    data = {} # :: timestamp -> {lat,lon,ele,hr}
    trkpts = @props.xml.getElementsByTagName 'trkpt'
    [maxEle, maxHR] = [-Infinity, -Infinity]
    avgLat = 0
    avgLon = 0

    for i in [0..trkpts.length-1]
      point = trkpts[i]
      timestamp = Date.parse point.getElementsByTagName('time')[0].innerHTML
      data[timestamp - @start] =
        lat: lat = point.getAttribute 'lat'
        lon: lon = point.getAttribute 'lon'
        ele: ele = point.getElementsByTagName('ele')[0].innerHTML
        hr: hr = point.getElementsByTagName('hr')[0]?.innerHTML

      avgLat += lat/trkpts.length
      avgLon += lon/trkpts.length
      maxEle = Math.max maxEle, ele
      maxHR = Math.max maxHR, hr

    name = @props.xml.querySelector('name').innerHTML


    # set up red/blue lines
    c = (if @state.dividerX?
      @state.dividerX * (@end - @start) / 800
    else
      if @props.cutoff? then @props.cutoff-@start else Infinity)
    lines =
      line1:
        points: ({latitude: x.lat, longitude: x.lon} for t,x of data when t < c),
        strokeColor: '#FF4136',
        strokeWeight: 3
      line2:
        points: ({latitude: x.lat, longitude: x.lon} for t,x of data when t >= c)
        strokeColor: '#0074D9'
        strokeWeight: 3

    points = if lines.line2.points[0]? then [lines.line2.points[0]] else []

    <div className='GPXView'>
      <h2>{name}</h2>
      # <MapBox
      #   apiToken='pk.eyJ1IjoiaWFtZGFuZm94IiwiYSI6ImhJUmlLZUUifQ.MjO_LzRrKOyWEuHPcBxDsg'
      #   id='myMap'
      #   latitude={avgLat}
      #   longitude={avgLon} 
      #   zoom=13 width=800 
      #   height=300 
      #   lines={lines} points={points} 
      # />
      <svg height=170 width=800 onMouseMove={@handleMove} onMouseLeave={@handleLeave} onClick={@onClick} ref='svg'>
        { <HRLine maxTime={@end} maxHR={maxHR} start={@start} data={data} /> unless isNaN maxHR }
        <EleView maxTime={@end} maxEle={maxEle} start={@start} data={data} />
        { <Divider start={@start} end={@end} cutoff={@props.cutoff} /> if @props.cutoff? }
        { <Cursor start={@start} end={@end} cutoff={@props.cutoff} dividerX={@state.dividerX} /> if @state.dividerX }
      </svg>
      { <p>Click above to split your activity.</p> unless @props.cutoff? }
      { <p><a href='#' onClick={@startAgain}>back</a></p> unless @props.cutoff? }
    </div>

  startAgain: ->
    @props.updateCutoff null
    @props.updateXML null

  handleMove: (e) ->
    rect = @refs.svg.getDOMNode().getBoundingClientRect()
    @setState dividerX: e.clientX-rect.left

  handleLeave: (e) ->
    @setState dividerX: null

  onClick: (e) ->
    c = @state.dividerX * (@end - @start) / 800 + @start
    @props.updateCutoff c


Divider = React.createClass
  render: ->
    cutoffX = (@props.cutoff - @props.start) * (800 / (@props.end - @props.start))
    <path className='cutoff' d={"M #{cutoffX} 0 #{cutoffX} 170"} />

Cursor = React.createClass
  render: ->
    c = @props.dividerX * (@props.end - @props.start) / 800
    <g>
      <path className='cursor' d={"M #{@props.dividerX} 0 #{@props.dividerX} 170"} />
      <rect x={@props.dividerX} y=0 width=50 height=27 fill='rgba(247,247,247,0.9)' />
      <text x={@props.dividerX+10} y=17>{nicetime(c)}</text>
    </g>


EleView = React.createClass
  #props: maxTime, maxEle, start, data
  render: ->
    duration = @props.maxTime - @props.start
    sfx = 800 / duration
    sfy = if @props.maxEle > 170 then 170 / @props.maxEle else 1
    points = (t*sfx + ' ' + obj.ele*-sfy for t,obj of @props.data).join ' '

    # final 'Z' tells the path to join up
    <g stroke='none' fill='rgba(0,0,0,0.15)' transform='translate(0,170)'>
      <path d={"M 0 #{@props.data[0].ele} L #{points} 800 0 Z"} />
    </g>


HRLine = React.createClass
  #props: maxTime, maxHR, start, data
  render: ->
    duration = @props.maxTime - @props.start
    sfx = 800 / duration
    sfy = 170 / @props.maxHR

    hrline = "M 0 "+@props.data[0].hr+" L"
    for t,obj of @props.data
      hrline += " #{t * sfx} #{obj.hr * -sfy}"

    <g stroke='#dd0447' strokeWidth='1.5' fill='none' transform='translate(0,170)'>
      <path d={hrline} />
    </g>


DownloadLinks = React.createClass
  getInitialState: ->
    downloadedForCutoff: null

  render: ->
    xml1 = @props.xml.cloneNode true
    xml2 = @props.xml.cloneNode true

    # do chopping
    [].forEach.call xml1.querySelectorAll('trkseg time'), (t) =>
      if Date.parse(t.innerHTML) >= @props.cutoff
        t.parentNode.remove() # chops out a trkpt

    xml1.querySelector('trk name').innerHTML += ' (part 1)'

    [].forEach.call xml2.querySelectorAll('trkseg time'), (t) =>
      if Date.parse(t.innerHTML) < @props.cutoff
        t.parentNode.remove() # chops out a trkpt

    xml2.querySelector('trk name').innerHTML += ' (part 2)'
    firstTime = xml2.querySelector('trk time').innerHTML
    xml2.querySelector('metadata time').innerHTML = firstTime

    # do serializing
    serializer = new XMLSerializer()

    newXMLString1 = serializer.serializeToString xml1
    blob1 = new Blob [newXMLString1]
    url1 = window.URL.createObjectURL blob1

    newXMLString2 = serializer.serializeToString xml2
    newXMLString2 = """<?xml version="1.0" encoding="UTF-8"?>\n""" + newXMLString2
    blob2 = new Blob [newXMLString2]
    url2 = window.URL.createObjectURL blob2

    <div className='downloadLinks'>
      <TinySummary xml={xml1} url={url1} filename='part1.gpx' handleClick={@handleClick} />
      <TinySummary xml={xml2} url={url2} filename='part2.gpx' handleClick={@handleClick} />
      { if @state.downloadedForCutoff is @props.cutoff
          <p>You can now <a href='http://www.strava.com/upload/select' target='_blank'>
          upload these files to Strava</a> or <a href='#' onClick={@startAgain}>start again</a>.</p>  }
      { if @state.downloadedForCutoff is @props.cutoff
          <p>Remember to delete the old activity!</p> }
    </div>

  handleClick: ->
    @setState downloadedForCutoff: @props.cutoff

  startAgain: ->
    @props.updateCutoff null
    @props.updateXML null


nicetime = (duration) ->
  seconds = Math.floor(duration / 1000)
  minutes = seconds / 60
  hours = Math.floor(minutes / 60)
  pad = (x) -> if x < 10 then '0' + x else x
  return (if hours > 0 then hours + ':' else '') + Math.floor(minutes) + ":" + pad(seconds % 60)


TinySummary = React.createClass
  #props: xml
  render: ->
    start = Date.parse(@props.xml.querySelector('trkseg trkpt:first-child time').innerHTML)
    end = Date.parse(@props.xml.querySelector('trkseg trkpt:last-child time').innerHTML)
    name = @props.xml.querySelector('name').innerHTML

    <p className='tinySummary'>
      <span className='duration'>{nicetime(end - start)}</span>
      <span className='label'>duration</span>
      <a href={@props.url} className='dl' download={@props.filename} onClick={@props.handleClick}>Download {@props.filename}</a>
    </p>


Blurb = React.createClass
  render: ->
    <div className='blurb'>
      <p><em>Use this tool to split Strava activities into separate parts.</em></p>
      <p>For example, if you've just done a triathlon, you might want to analyse each
      phase as a separate activity.</p>
      <p>You'll need to export the GPX file from your Strava activity -
      click the wrench icon. You can then split it up and then upload the two parts.</p>
    </div>


Footer = React.createClass
  render: ->
    <p className='footer'>made for fun by <a href='http://github.com/iamdanfox/gpxsplitter'>iamdanfox</a></p>
