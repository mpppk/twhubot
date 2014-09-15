module.exports = (robot) ->
  robot.on 'followed', (event) ->
    @robot.logger.info "followed #{event.user.name}!"
    robot.adapter.join event.user
