
{div,form,input,p,h1,a,button,svg,rect} = React.DOM

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
      (p {}, "Upload a gpx file"),
      (form {}, (input {type:'file',onChange:@handleFile}) ),
      if @state.xml? then FileView(@state) else null,
      if @state.cutoff? then DownloadView(@state) else null
    ])
})

FileView = React.createClass({
  render: () ->
    name = @props.xml.querySelector('name').innerHTML
    start = Date.parse(@props.xml.querySelector('trkseg trkpt:first-child time').innerHTML)
    end = Date.parse(@props.xml.querySelector('trkseg trkpt:last-child time').innerHTML)

    # elevation bar chart - TODO switch to line / region?
    bars = []
    allpoints = @props.xml.getElementsByTagName('ele')
    barwidth = 600 / allpoints.length
    for i in [0..allpoints.length-1]
      h = allpoints[i].innerHTML
      bars.push( rect {height:h,width:barwidth,x:i*barwidth,y:100-h,fill:'black',stroke:'none'} )

    # TODO heartrate line

    return (div {className:'fileView'}, [
      (h1 {}, name),
      (svg {height:100,width:600}, bars)
      (p {}, start + " to " + end),
      Selector({start:start,end:end,cutoff:@props.cutoff,updateCutoff:@props.updateCutoff})
    ])
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
