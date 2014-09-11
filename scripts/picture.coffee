# Description:
# hubot remember your taken picture
#
# Commands:
# pic <title> - save your picture title
#
module.exports = (robot) ->
  # 撮った写真
  class Picture
    _title     = ""          # -> 写真の名前
    _date      = null        # -> 撮影日時
    _isCorrect = false       # -> 正解かどうか
    constructor: (title) ->
      _title = title
      _date = new Date()
    
    getTitle: ->
      _title
    
    toObject: ->
      {title:_title, date:_date, isCorrect:_isCorrect}

  # ユーザーごとに保持する情報
  class TourMember
    _db = null
    constructor: (name) ->
      users = robot.brain.usersForFuzzyName(name)
      if users.length > 1
        msg.send getAmbiguousUserText users
        return
      else if users.length is 0
        msg.send "#{name}というユーザーはいません。"
        return
      
      users[0].tour = users[0].tour or {} 
      _db = users[0].tour
      _dbInitialize.call @
    
    # 指定されたrobot.brain.user内のデータを初期化する
    _dbInitialize = ->
      _db.pics = _db.pics or []
      
    getPics: ->
      _db.pics

    # 与えられたタイトルの写真を追加する.
    # まだ撮影していないタイトルであればture、既に撮影していればfalseを返す
    addPicture: (title) =>
      newPic = new Picture(title)
      pics = ( pic for pic in _db.pics when pic.title is newPic.getTitle() )
      if pics.length > 0
        return "#{pics[0].title} という名前の写真は既に存在します。"
      _db.pics.push(newPic.toObject())
      "写真名「#{newPic.getTitle()}」を受け付けました。"

    deleteTourData: =>
      _db.pics = [] # tourごと{}で置き換えようとすると失敗するので注意

  # 指定されたタイトルの写真を追加する
  robot.hear /pic (.*)$/i, (msg) ->
    picTitle = msg.match[1]
    name = msg.message.user.name
    tm = new TourMember(name)
    msg.reply tm.addPicture(picTitle)

  # ツアーの情報をすべて削除する
  robot.hear /tour realy all clean$/i, (msg) ->
    name = msg.message.user.name
    tm = new TourMember(name)
    tm.deleteTourData()
    msg.reply "tour data deleted."

