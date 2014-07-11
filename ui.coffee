
{div,form,input,p,h1,h2,a,button,svg,rect,path,g} = React.DOM

App = React.createClass({
  getInitialState: () -> {
    xml:        null
    cutoff:     null
    updateCutoff: @updateCutoff
  }

  handleFile: (e) ->
    reader = new FileReader()
    reader.onload = (evt) =>
      parser = new DOMParser()
      xml = parser.parseFromString(evt.target.result, 'text/xml')
      @setState(xml:xml)

    reader.readAsText(e.target.files[0])

  updateCutoff: (newCutoff) ->
    @setState(cutoff:newCutoff)

  render: () ->
    (div {className:'app'}, [
      (h1 {}, "Strava Split")
      if not @state.xml? then (p {}, "Upload a gpx file") else null,
      if not @state.xml? then (form {}, (input {type:'file',onChange:@handleFile}) ) else null,
      if @state.xml? then GPXView(@state) else null,
      if @state.cutoff? then DownloadView(@state) else null
    ])
})

GPXView = React.createClass({
  getInitialState: () -> {
    dividerX : 300
  }
  render: () ->
    # pre-process data
    @start = Date.parse(@props.xml.querySelector('trkseg trkpt:first-child time').innerHTML)
    @end = Date.parse(@props.xml.querySelector('trkseg trkpt:last-child time').innerHTML)
    data = {} # :: timestamp -> {lat,lon,ele,hr}
    trkpts = @props.xml.getElementsByTagName('trkpt')
    [maxEle, maxHR, maxTime] = [-Infinity, -Infinity, -Infinity] # TODO: maxTime & end are the same

    for i in [0..trkpts.length-1]
      point = trkpts[i]
      timestamp = Date.parse(point.getElementsByTagName('time')[0].innerHTML)
      data[timestamp - @start] = {
        lat: point.getAttribute('lat')
        lon: point.getAttribute('lon')
        ele: ele = point.getElementsByTagName('ele')[0].innerHTML
        hr: hr = point.getElementsByTagName('hr')[0].innerHTML
      }
      maxEle = Math.max maxEle, ele
      maxHR = Math.max maxHR, hr
      maxTime = Math.max maxTime, timestamp

    name = @props.xml.querySelector('name').innerHTML

    return (div {className:'GPXView'}, [
      (h2 {}, name),
      (svg {height:100,width:600,onMouseMove:@handleMove,onMouseLeave:@handleLeave,onClick:@onClick,ref:'svg'}, [
        HRLine({maxTime:maxTime,maxHR:maxHR,start:@start,data:data}),
        EleView({maxTime:maxTime,maxEle:maxEle,start:@start,data:data}),
        Divider({start:@start,end:@end,cutoff:@props.cutoff,dividerX:@state.dividerX})
      ])
    ])
  handleMove: (e) ->
    rect = @refs.svg.getDOMNode().getBoundingClientRect();
    @setState(dividerX:e.clientX-rect.left)
  handleLeave: (e) ->
    @setState(dividerX:null)
  onClick: (e) ->
    c = @state.dividerX * (@end - @start) / 600 + @start
    @props.updateCutoff(c)
 })

Divider = React.createClass({
  render: () ->
    (g {}, [
      if @props.cutoff?
        cutoffX = (@props.cutoff - @props.start) * (600 / (@props.end - @props.start))
        (path {className:'cutoff',d:"M #{cutoffX} 0 #{cutoffX} 100"})
      else null,
      if @props.dividerX?
        (path {className:'cursor',d:"M #{@props.dividerX} 0 #{@props.dividerX} 100"})
      else null
    ])
})

EleView = React.createClass({
  #props: maxTime, maxEle, start, data
  render: () ->
    duration = @props.maxTime - @props.start
    sfx = 600 / duration
    sfy = if @props.maxEle > 100 then 100 / @props.maxEle else 1

    elePath = "M 0 #{@props.data[0].ele} L " + (t*sfx + " "+ obj.ele*-sfy for t,obj of @props.data).join(' ') + " 600 0 Z"
    # final 'Z' tells the path to join up
    return (g {stroke:'none', fill:'rgba(0,0,0,0.15)',transform:"translate(0,100)"}, (path {d:elePath}))
})

HRLine = React.createClass({
  #props: maxTime, maxHR, start, data
  render: () ->
    duration = @props.maxTime - @props.start
    sfx = 600 / duration
    sfy = 100 / @props.maxHR

    hrline = "M 0 "+@props.data[0].hr+" L"
    for t,obj of @props.data
      hrline += " #{t * sfx} #{obj.hr * -sfy}"

    return (g {stroke:'#dd0447',strokeWidth:'1.5', fill:'none',transform:"translate(0,100)"}, (path {d:hrline}))
})

DownloadView = React.createClass({
  getInitialState: () -> {
    computed: null
  }

  handleClick: () ->
    @setState(computed:@props.cutoff)

  render: () ->
    (div {className:'downloadView',ref:'container'},
      if @state.computed is @props.cutoff
        DownloadLinks(@props)
      else
        (button {onClick:@handleClick}, "Split")
    )
})

DownloadLinks = React.createClass({
  render: () ->
    xml1 = @props.xml
    xml2 = xml1.cloneNode(true)

    # do chopping
    [].forEach.call( xml1.querySelectorAll('trkseg time'), (t) =>
      if Date.parse(t.innerHTML) >= @props.cutoff
        t.parentNode.remove() # chops out a trkpt
    )
    xml1.querySelector('trk name').innerHTML += " (part 1)"

    [].forEach.call( xml2.querySelectorAll('trkseg time'), (t) =>
      if Date.parse(t.innerHTML) < @props.cutoff
        t.parentNode.remove() # chops out a trkpt
    )
    xml2.querySelector('trk name').innerHTML += " (part 2)"
    firstTime = xml2.querySelector('trk time').innerHTML
    xml2.querySelector('metadata time').innerHTML = firstTime

    # do serializing
    serializer = new XMLSerializer()

    newXMLString1 = serializer.serializeToString(xml1)
    href1 = "data:application/gpx+xml;base64,"+btoa(newXMLString1)

    newXMLString2 = serializer.serializeToString(xml2)
    newXMLString2 = """<?xml version="1.0" encoding="UTF-8"?>\n""" + newXMLString2
    href2 = "data:application/gpx+xml;base64,"+btoa(newXMLString2)

    (div {},[
      (p {}, "Right click and select 'Save link as'"),
      (a {href:href1}, "Download Part 1"),
      (a {href:href2}, "Download Part 2")
    ])
})
