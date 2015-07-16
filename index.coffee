SLACK_ACCOUNT = process.env.SLACK_ACCOUNT || "Slack2.Me"
SLACK_TOKEN   = process.env.SLACK_TOKEN || ""
CATER2ME_GUID = process.env.CATER2ME_GUID || ""
SLACK_HOOK_URL = process.env.SLACK_HOOK_URL || ""

express = require('express')
bodyParser = require('body-parser')
request = require('request')
http = require('http')
cheerio = require('cheerio')

app = express()

app.use(bodyParser.json())
app.use(bodyParser.urlencoded())

app.get('/', (req, res) ->
  res.send('Up and running')
)

post_to_slack = (params, menuText) ->
  dayText = if params.text?.toLowerCase() is "tomorrow" then "Tomorrow" else "Today"
  payload = "#{dayText}\'s lunch:\n #{menuText}"

  req_options = {
    url: SLACK_HOOK_URL,
    method: 'POST',
    json: {
      "channel": "##{params.channel_name}",
      "text": payload,
      "username": SLACK_ACCOUNT,
      "icon_emoji":":cubimal_chick:"
    }
  }
  console.log "Sending Menu to Slack"
  request(req_options)

addZero = (n) ->
  if n < 10
    return '0'+n
  else
    return ''+n

formatMeal = (restaurant, description, items, image) ->
  text = "<#{image}>\n"
  text += "*#{restaurant}*\n"
  text += "_#{description}_\n"
  for item in items
    text += "\n • #{item}"

  return text

app.post('/', (req, res) ->
  console.log '### REQUEST'

  params = req.body
  console.log "Grabbing cater2me menu"
  url = "http://www.cater2.me/clients/#{CATER2ME_GUID}/orders.json"
  request(url, (err, response, body) ->
    return res.send(500) if err?
    date = new Date()
    if params.text is "tomorrow"
      date.setDate(date.getDate()+1)
    year = date.getFullYear()

    month = addZero(date.getMonth()+1)
    day = addZero(date.getDate())

    dateStamp = "#{year},#{month},#{day}"

    menu = JSON.parse(body)["timeline"]

    for meal in menu["date"]
      date = meal["startDate"].substr(0,10)
      if meal["startDate"].substr(0,10) is dateStamp
        image = meal.asset?.media
        caption = meal.asset?.caption
        caption = caption.replace(/<br\/>/g, " ")

        $headline = cheerio.load meal.headline
        restaurant = $headline("h3").text()

        $text = cheerio.load meal.text, {normalizeWhitespace: true}
        $text(".alergy_icons").remove()
        $text(".text-warning").remove()
        $text(".text-success").remove()
        entrees = $text("li")
        entreeText = []
        entrees.each( (i, elm) ->
          entreeText.push $text(this).text()
        )
        replyText = formatMeal(restaurant, caption, entreeText, image)
        break
    return     
    if replyText?
      post_to_slack(req.body, replyText)
    else
      res.send(500, "Couldn't find any meals Today")
  )
)

http.createServer(app).listen 4567, (err) ->
  if err?
    console.log 'Could not start server:'
    console.log err
  else
    console.log 'Starting server'
