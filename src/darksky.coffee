# Description
#   Grabs the current forecast from Dark Sky
#
# Dependencies
#   None
#
# Configuration
#   HUBOT_DARK_SKY_API_KEY
#   HUBOT_DARK_SKY_DEFAULT_LOCATION
#   HUBOT_DARK_SKY_SEPARATOR (optional - defaults to "\n")
#
# Commands:
#   hubot weather - Get the weather for HUBOT_DARK_SKY_DEFAULT_LOCATION
#   hubot weather <location> - Get the weather for <location>
#
# Notes:
#   If HUBOT_DARK_SKY_DEFAULT_LOCATION is blank, weather commands without a location will be ignored
#
# Author:
#   kyleslattery
#   awaxa
module.exports = (robot) ->
  robot.respond /weather ?(.+)?/i, (msg) ->
    location = msg.match[1] || process.env.HUBOT_DARK_SKY_DEFAULT_LOCATION
    return if not location

    options =
      separator: process.env.HUBOT_DARK_SKY_SEPARATOR
    unless options.separator
      options.separator = "\n"

    osmurl = "https://nominatim.openstreetmap.org/search"
    qu = format: "json", limit: "1", q: location
    msg.http(osmurl)
      .query(qu)
      .get() (err, res, body) ->
        result = JSON.parse(body)

        if result.length > 0
          lat = result[0].lat
          lng = result[0].lon
          darkSkyMe msg, lat,lng , options.separator, (darkSkyText) ->
            response = "Weather for #{result[0].display_name} (Powered by DarkSky https://darksky.net/poweredby/)#{options.separator}#{darkSkyText}"
              .replace /-?(\d+\.?\d*)°C/g, (match) ->
                centigrade = match.replace /°C/, ''
                match = Math.round(centigrade*10)/10 + '°C/' + Math.round(centigrade * (9/5) + parseInt(32, 10)) + '°F'
            response += "#{options.separator}"
            msg.send response
        else
          msg.send "Couldn't find #{location}"

darkSkyMe = (msg, lat, lng, separator, cb) ->
  url = "https://api.darksky.net/forecast/#{process.env.HUBOT_DARK_SKY_API_KEY}/#{lat},#{lng}/?units=si"
  msg.http(url)
    .get() (err, res, body) ->
      result = JSON.parse(body)

      if result.error
        cb "#{result.error}"
        return

      response = "Currently: #{result.currently.summary} #{result.currently.temperature}°C"
      response += "#{separator}Today: #{result.hourly.summary}"
      response += "#{separator}Coming week: #{result.daily.summary}"
      cb response
