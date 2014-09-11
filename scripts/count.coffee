# Description:
# test for add new key to user
#
# Commands:
# hubot countup - count up user's count
# hubot count - show current count

module.exports = (robot) ->
  robot.respond /count reset$/i, (msg) ->
   name = msg.message.user.name
   users = robot.brain.usersForFuzzyName(name)
   if users.length is 1
     user = users[0]
     user.counts = 0
     msg.send "#{msg.message.user.name}'s count reset"
   else if users.length > 1
     msg.send getAmbiguousUserText users
   else
     msg.send "#{name}なんて知らんで"
# msg.send usr.counts or []

  robot.respond /count up$/i, (msg) ->
    name = msg.message.user.name
    users = robot.brain.usersForFuzzyName(name)
    if users.length is 1
      # 全体の合計を計算
      robot.brain.data.totalCount = robot.brain.data.totalCount or 0
      robot.brain.data.totalCount = Number( robot.brain.data.totalCount )+ 1
      user = users[0]
      user.counts = user.counts or 0
      user.counts = Number(user.counts) + 1
      msg.send "#{msg.message.user.name}'s count is #{user.counts}."
    else if users.length > 1
      msg.send getAmbiguousUserText users
    else
      msg.send "#{name}? 誰やねん"
