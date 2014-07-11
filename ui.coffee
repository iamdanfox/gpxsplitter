
{div,form,input,p,h1,a,button,svg,rect,path,g} = React.DOM

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
    (div {}, [
      (h1 {}, "Strava Split")
      if not @state.xml? then (p {}, "Upload a gpx file") else null,
      if not @state.xml? then (form {}, (input {type:'file',onChange:@handleFile}) ) else null,
      if @state.xml? then FileView(@state) else null,
      if @state.cutoff? then DownloadView(@state) else null
    ])
})

FileView = React.createClass({
  render: () ->
    name = @props.xml.querySelector('name').innerHTML
    start = Date.parse(@props.xml.querySelector('trkseg trkpt:first-child time').innerHTML)
    end = Date.parse(@props.xml.querySelector('trkseg trkpt:last-child time').innerHTML)

    # pre-process data
    data = {} # :: timestamp -> {lat,lon,ele,hr}
    trkpts = @props.xml.getElementsByTagName('trkpt')
    [maxEle, maxHR, maxTime] = [-Infinity, -Infinity, -Infinity]

    for i in [0..trkpts.length-1]
      point = trkpts[i]
      timestamp = Date.parse(point.getElementsByTagName('time')[0].innerHTML)
      data[timestamp - start] = {
        lat: point.getAttribute('lat')
        lon: point.getAttribute('lon')
        ele: ele = point.getElementsByTagName('ele')[0].innerHTML
        hr: hr = point.getElementsByTagName('hr')[0].innerHTML
      }
      maxEle = Math.max maxEle, ele
      maxHR = Math.max maxHR, hr
      maxTime = Math.max maxTime, timestamp

    return (div {className:'fileView'}, [
      (h1 {}, name),
      (svg {height:100,width:600}, [
        HRLine({maxTime:maxTime,maxHR:maxHR,start:start,data:data}),
        EleView(@props)
      ])
      (p {}, start + " to " + end),
      Selector({start:start,end:end,cutoff:@props.cutoff,updateCutoff:@props.updateCutoff})
    ])
})

EleView = React.createClass({
  #props:
  render: () ->
    # elevation bar chart - TODO switch to line / region? - TODO switch to use timestamp on x axis!
    bars = []
    allpoints = @props.xml.getElementsByTagName('ele')
    barwidth = 600 / allpoints.length
    for i in [0..allpoints.length-1]
      h = allpoints[i].innerHTML
      bars.push( rect {height:h,width:barwidth,x:i*barwidth,y:100-h,fill:'black',stroke:'none'} )

    return (g {}, bars)
})

HRLine = React.createClass({
  #props: maxTime, maxHR, start, data
  render: () ->
    duration = @props.maxTime - @props.start
    sfx = 600 / duration
    sfy = 100 / @props.maxHR
    hrline = "M 0 "+@props.data[0].hr+" L"
    # HR line # TODO check maxHR
    for t,obj of @props.data
      hrline += " #{t * sfx} #{obj.hr * -sfy}"

    return (g {}, (path {d:hrline,stroke:'#dd0447',strokeWidth:'1.5', fill:'none',transform:"translate(0,100)"}))
})

Selector = React.createClass({
  getInitialState:() -> {
      value:(@props.start + @props.end)/2
    }
  handleChange: () ->
    val = @refs.slider.getDOMNode().value
    @props.updateCutoff(val)
  render: () ->
    (input {
      type:'range',
      min:@props.start,
      max:@props.end,
      defaultValue:@props.cutoff,
      ref:'slider',
      onChange:@handleChange
    })
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
