apiKey: '' # put your forcast.io api key inside the quotes here

refreshFrequency: 60000

style: """
  bottom: 15%
  left: 50%
  margin: 0 0 0 -100px
  font-family: Berlin, Helvetica Neue
  color: #fff

  @font-face
    font-family Weather
    src url(pretty-weather.widget/icons.svg) format('svg')

  .icon
    font-family: Weather
    font-size: 40px
    text-anchor: middle
    alignment-baseline: middle

  .temp
    font-size: 20px
    text-anchor: middle
    alignment-baseline: baseline

  .outline
    fill: none
    stroke: #fff
    stroke-width: 0.5

  .icon-bg
    fill: rgba(#fff, 0.95)

  .summary
    text-align: center
    border-top: 1px solid #fff
    padding: 12px 0 0 0
    margin-top: -20px
    font-size: 14px
    max-width: 200px
    line-height: 1.4

  .date, .location
    fill: #fff
    stroke: #fff
    stroke-width: 1px
    font-size: 12px
    text-anchor: middle

  .date
    fill: #ccc
    stroke: #ccc

  .date.mask
    stroke: #999
    stroke-width: 5px
"""

command: "echo {}"

render: (o) -> """
  <svg #{@svgNs} width="200px" height="200px" >
    <defs xmlns="http://www.w3.org/2000/svg">
      <mask id="icon_mask">
        <rect width="100px" height="100px" x="50" y="50" fill="#fff"
              transform="rotate(45 100 100)"/>
        <text class="icon"
              x="50%" y='45%'></text>

        <text class="temp"
              x="50%" y='65%' dx='3px'></text>
      </mask>
      <mask id="text_mask">
        <rect x='0' y="0" width="200px" height="200px" fill='#fff'/>
        <text class="location mask"
            textLength='90px'
            transform="rotate(-45 100 100)"
            x="50%" y='42px'></text>
        <text class="date mask"
            textLength='90px'
            transform="rotate(45 100 100)"
            x="50%" y='42px'></text>
      </mask>
    </defs>

    <g mask="url(#text_mask)">
      <rect class='outline' width="100px" height="100px" x="50" y="50"/>
      <rect class='outline' width="100px" height="100px" x="50" y="50"
            transform="rotate(21 100 100)"/>
      <rect class='outline' width="100px" height="100px" x="50" y="50"
            transform="rotate(66 100 100)"/>
    </g>

    <rect class='icon-bg' width="200px" height="200px" x="0" y="0"

          mask="url(#icon_mask)"/>

    <text class="location"
          textLength='90px'
          transform="rotate(-45 100 100)"
          x="50%" y='42px'></text>
    <text class="date"
          textLength='90px'
          transform="rotate(45 100 100)"
          x="50%" y='42px'></text>
  </svg>
  <div class='summary'></div>
"""

svgNs: 'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"'

afterRender: (domEl) ->
  geolocation.getCurrentPosition (e) =>
    coords     = e.position.coords
    [lat, lon] = [coords.latitude, coords.longitude]
    @command   = @makeCommand(@apiKey, "#{lat},#{lon}")

    $(domEl).find('.location').prop('textContent', e.address.city)
    @refresh()


makeCommand: (apiKey, location) ->
  exclude  = "minutely,hourly,alerts,flags"
  "curl -sS 'https://api.forecast.io/forecast/#{apiKey}/#{location}?units=auto&exclude=#{exclude}'"

update: (output, domEl) ->
  data  = JSON.parse(output)
  today = data.daily?.data[0]

  return unless today?
  date  = @getDate today.time

  $(domEl).find('.temp').prop 'textContent', Math.round(today.temperatureMax)+'°'
  $(domEl).find('.summary').text today.summary
  $(domEl).find('.icon')[0]?.textContent = @getIcon(today)
  $(domEl).find('.date').prop('textContent',@dayMapping[date.getDay()])


dayMapping:
  0: 'Sunday'
  1: 'Monday'
  2: 'Tuesday'
  3: 'Wednesday'
  4: 'Thursday'
  5: 'Friday'
  6: 'Saturday'

iconMapping:
  "rain"                :"\uf019"
  "snow"                :"\uf01b"
  "fog"                 :"\uf014"
  "cloudy"              :"\uf013"
  "wind"                :"\uf021"
  "clear-day"           :"\uf00d"
  "mostly-clear-day"    :"\uf00c"
  "partly-cloudy-day"   :"\uf002"
  "clear-night"         :"\uf02e"
  "partly-cloudy-night" :"\uf031"
  "unknown"             :"\uf03e"

getIcon: (data) ->
  return @iconMapping['unknown'] unless data

  if data.icon.indexOf('cloudy') > -1
    if data.cloudCover < 0.25
      @iconMapping["clear-day"]
    else if data.cloudCover < 0.5
      @iconMapping["mostly-clear-day"]
    else if data.cloudCover < 0.75
      @iconMapping["partly-cloudy-day"]
    else
      @iconMapping["cloudy"]
  else
    @iconMapping[data.icon]

getDate: (utcTime) ->
  date  = new Date(0)
  date.setUTCSeconds(utcTime)
  date

