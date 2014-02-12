# Description:
#   Record and retrieve comments for retro 
#
# Commands:
#   [good|bad|park]: some comment - store a comment
#   hubot retro 1/1 - show all comments since 1/1

module.exports = (robot) ->

  robot.hear regex, (msg) ->
    type = msg.match[0]
    date = new Date()
    
    @robot.brain.data.retro ||= {}
    @robot.brain.data.retro[date.getFullYear()] ||= {}
    @robot.brain.data.retro[date.getFullYear()][date.getMonth()] ||= {}
    @robot.brain.data.retro[date.getFullYear()][date.getMonth()][date.getDate()] ||= []
    @robot.brain.data.retro[date.getFullYear()][date.getMonth()][date.getDate()].push
      user: msg.message.user.name
      type: msg.match[1]
      message: msg.match[2]

    msg.send "Noted, #{msg.message.user.name}, I'll remember that for retro. Enter \"hubot retro month/day[/year]\" to see all retro comments since a given date."

  robot.respond /retro (.*)$/i, (msg) ->

    date_arr = msg.match[1].split('/')
    month = parseInt(date_arr[0]) - 1
    day = parseInt(date_arr[1])
    year = parseInt(date_arr[2])

    if isNaN(month) || isNaN(day)
      msg.send "Please secifify a start date as month/day or month/day/year"
      return

    today = new Date()

    if isNaN(year)
      if month <= today.getMonth()
        year = today.getFullYear()
      else
        year = today.getFullYear() - 1
    else
      if year < 100
        year += (Math.floor(today.getFullYear() / 100) * 100)

    date = new Date(year, month, day)
    msg.send "Showing retro comments since #{date}.\n"

    items = {}
    items.good = []
    items.bad = []
    items.park = []

    while date < today
      day_list = null
      try 
        day_list = @robot.brain.data.retro[date.getFullYear()][date.getMonth()][date.getDate()]
      catch 
        # do nothing

      if day_list?
        for item in day_list
          items[item.type].push item

      date.setDate(date.getDate() + 1)

    string = ''
    string += "\nGood\n"
    string += "  #{item.user}:#{item.message}\n" for item in items.good

    string += "\nBad\n"
    string += "  #{item.user}:#{item.message}\n" for item in items.bad

    string += "\nPark\n"
    string += "  #{item.user}:#{item.message}\n" for item in items.park

    msg.send string


regex = new RegExp /^(good|bad|park)\:(.*)$/






