# Description:
#   Record and retrieve comments for retro 
#
# Commands:
#   [good|bad|park]: <comment> - store a comment
#   hubot retro - show all comments in the last 2 weeks
#   hubot retro <month>/<day>[/<year>] - show all comments since <month>/<day>[/<year>]
#   hubot retro <month>/<day>[/<year>] <month>/<day>[/<year>] - show all comments between the given dates

module.exports = (robot) ->

  # old colon syntax
  robot.hear /^(good|bad|park)\:(.*)$/, handle_comment

  # Andy's requested "hubot good ..." syntax
  robot.respond /(good|bad|park)(.*)$/i, handle_comment
  
  robot.respond /retro\s*([^\s]+)?\s?([^\s]+)?$/i, (msg) ->

    end_date = new Date()

    if (!msg.match[1]?)
      start_date = weeks_ago(2)
    else if msg.match[2]?.match(/weeks?/)
      start_date = weeks_ago(parseInt(msg.match[1]))
    else if msg.match[2]?.match(/days?/)
      start_date = days_ago(parseInt(msg.match[1]))
    else
      start_date = date_from_string(msg.match[1])
      unless start_date?
        msg.send "Please specify a start date as <month>/<day>, <month>/<day>/<year>, <number> weeks, <number> days, or just leave blank for default 2 weeks"
        return

      end_date_string = msg.match[2]
      if end_date_string?
        end_date = date_from_string(end_date_string)
        unless end_date
          msg.send "Please specify the end date as <month>/<day> or <month>/<day>/<year> or leave emtpy for the current date"
          return


    msg.send "Showing retro comments from #{start_date.toLocaleDateString("en-US")} to #{end_date.toLocaleDateString("en-US")}.\n"

    items = {}
    items.good = []
    items.bad = []
    items.park = []

    while start_date < end_date
      day_list = null
      try 
        day_list = @robot.brain.data.retro[msg.message.room][start_date.getFullYear()][start_date.getMonth()][start_date.getDate()]
      catch 
        # do nothing

      if day_list?
        for item in day_list
          items[item.type].push item

      start_date.setDate(start_date.getDate() + 1)

    string = ''
    string += "\nGood\n"
    string += "  #{item.user}:#{item.message}\n" for item in items.good

    string += "\nBad\n"
    string += "  #{item.user}:#{item.message}\n" for item in items.bad

    string += "\nPark\n"
    string += "  #{item.user}:#{item.message}\n" for item in items.park

    msg.send string

date_from_string = (string) ->
  return unless string?

  weeks_arr = string.match(/(\d)\s*\weeks?/)
  return weeks_ago(weeks_arr[1]) if weeks_arr?

  date_arr = string.split('/')
  month = parseInt(date_arr[0]) - 1
  day = parseInt(date_arr[1])
  year = parseInt(date_arr[2])
  today = new Date()

  if isNaN(month) || isNaN(day)
    return null

  if isNaN(year)
    if month <= today.getMonth()
      year = today.getFullYear()
    else
      year = today.getFullYear() - 1
  else
    if year < 100
      year += (Math.floor(today.getFullYear() / 100) * 100)

  new Date(year, month, day)

days_ago = (days) ->
  milliseconds_per_day = 86400000
  new Date(+new Date - milliseconds_per_day * (days - 1))

weeks_ago = (weeks) ->
  days_ago(weeks * 7)

handle_comment = (msg) ->
  type = msg.match[0]
  date = new Date()
  
  @robot.brain.data.retro ||= {}
  @robot.brain.data.retro[msg.message.room] ||= {}
  @robot.brain.data.retro[msg.message.room][date.getFullYear()] ||= {}
  @robot.brain.data.retro[msg.message.room][date.getFullYear()][date.getMonth()] ||= {}
  @robot.brain.data.retro[msg.message.room][date.getFullYear()][date.getMonth()][date.getDate()] ||= []
  @robot.brain.data.retro[msg.message.room][date.getFullYear()][date.getMonth()][date.getDate()].push
    user: msg.message.user.name
    type: msg.match[1]
    message: msg.match[2]

  msg.send "Noted, #{msg.message.user.name}, I'll remember that for retro! Enter \"hubot retro <start_date> [<end_date>]\" to see all retro comments between the given dates. Date format: <month>/<day>[/<year>]"







