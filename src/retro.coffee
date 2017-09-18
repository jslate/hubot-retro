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

    while start_date <= end_date
      day_list = null
      try
        day_list = @robot.brain.data.retro[get_channel_id(msg)][start_date.getFullYear()][start_date.getMonth()][start_date.getDate()] || []
        # add any left over items from before we started recording the channel
        day_list = day_list.concat(@robot.brain.data.retro[start_date.getFullYear()][start_date.getMonth()][start_date.getDate()] || [])
      catch
        # do nothing

      if day_list?
        for item in day_list
          items[item.type.toLowerCase()].push item

      start_date.setDate(start_date.getDate() + 1)

    item_arrays = []
    item_arrays = item_arrays.concat ["\nGood"]
    item_arrays = item_arrays.concat get_items_string(items.good)
    item_arrays = item_arrays.concat ["\nBad"]
    item_arrays = item_arrays.concat get_items_string(items.bad)
    item_arrays = item_arrays.concat ["\nPark"]
    item_arrays = item_arrays.concat get_items_string(items.park)

    msg.send item_arrays.join("\n")

get_items_string = (items) ->
  "#{item.user}:#{item.message} #{if item.channel then '' else '(channel unknown)'}" for item in items

get_channel_name = (response, robot) ->
  channel_id = get_channel_id(response)
  robot.adapter.client.rtm.dataStore.getChannelById(room).name

get_channel_id = (response) ->
  if response.message.room == response.message.user.name
    "@#{response.message.room}"
  else
    "##{response.message.room}"

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
  d = new Date(+new Date - milliseconds_per_day * (days - 1))
  new Date(1900 + d.getYear(), d.getMonth(), d.getDate())

weeks_ago = (weeks) ->
  days_ago(weeks * 7)

handle_comment = (msg) ->
  type = msg.match[0]
  date = new Date()
  channel_id = get_channel_id(msg)
  channel_name = get_channel_name(msg, @robot)

  @robot.brain.data.retro ||= {}
  @robot.brain.data.retro[channel_id] ||= {}
  @robot.brain.data.retro[channel_id][date.getFullYear()] ||= {}
  @robot.brain.data.retro[channel_id][date.getFullYear()][date.getMonth()] ||= {}
  @robot.brain.data.retro[channel_id][date.getFullYear()][date.getMonth()][date.getDate()] ||= []
  @robot.brain.data.retro[channel_id][date.getFullYear()][date.getMonth()][date.getDate()].push
    user: msg.message.user.name
    type: msg.match[1]
    message: msg.match[2]
    channel: channel_name

  msg.send "Noted, #{msg.message.user.name} in #{channel_name}, I'll remember that for retro!"
