
{div,form,input,p,h1,a,button} = React.DOM

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
    (div {className:'fileView'}, [
      (h1 {}, name),
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
        DownloadLinks()
      else
        (button {onClick:@handleClick}, "Split")
    )
})

DownloadLinks = React.createClass({
  render: () ->
    # do chopping

    # do serializing

    href1 = "http://google.com"
    href2 = "http://google.co.uk"
    (div {},[
      (p {}, "Right click and select 'Save link as'"),
      (a {href:href1}, "Download Part 1"),
      (a {href:href2}, "Download Part 2")
    ])
})
