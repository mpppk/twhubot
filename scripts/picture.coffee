# Description:
# hubot remember your taken picture
#
# Commands:
# pic <title> - save your picture title
#
request = require('request');
options = {
  url: 'https://dl.dropboxusercontent.com/u/18427716/test.json',
  json: true
};

module.exports = (robot) ->
	# robot.brain内のツアー情報へのラッパー
	class CorrectPictureDB
		_cpics = []
		getCPics = ->
			console.log "loading correct data..."
			request.get(options, (error, response, body) ->
				if !error && response.statusCode == 200
					_cpics = body
					console.log "data loading finished."
				else
					console.log 'error: '+ response.statusCode;
			)
		getCPics()

		constructor: ->
			
		# 与えられたタイトルの写真が正解かどうか
		@isCorrect = (title) ->
			correctPics = _cpics.correctPics
			pics = ( pic for pic in correctPics when pic.title is title )
			return true if pics.length > 0
			false

	# 撮った写真
	class Picture
		constructor: (title) ->
			_title = title
			_date = new Date()
			_isCorrect = false
			
			# public method
			@getTitle = ->
				_title
			
			@toObject = ->
				{title:_title, date:_date, isCorrect:_isCorrect}
	
	# ユーザーごとに保持する情報
	class TourMember
		constructor: (name) ->
			# ---- private instance field/method ----
			_db = null
			
			# 指定されたrobot.brain.user内のデータを初期化する
			_dbInitialize = ->
				_db.pics = _db.pics or []
			# ---- private instance field/method ----
			
			# ---- public method ----
			@getPics = ->
				_db.pics
			
			# 与えられたタイトルの写真を追加する.
			# まだ撮影していないタイトルであればture、既に撮影していればfalseを返す
			@addPicture = (title) =>
				newPic = new Picture(title)
				pics = ( pic for pic in _db.pics when pic.title is newPic.getTitle() )
				if pics.length > 0
					return "#{pics[0].title} という名前の写真は既に存在します。"
				newPicObj = newPic.toObject()
				newPicObj.isCorrect = CorrectPictureDB.isCorrect newPic.getTitle()
				_db.pics.push newPicObj
				"写真名「#{newPic.getTitle()}」を受け付けました。#{newPicObj.isCorrect}"
			# ---- public method ----
			
			@deleteTourData = ->
				console.log _db.pics
				_db.pics = [] # tourごと{}で置き換えようとすると失敗するので注意
		 
			# constroctor
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
	# 指定されたタイトルの写真を追加する
	robot.hear /pic (.*)$/i, (msg) ->
		picTitle = msg.match[1]
		name = msg.message.user.name
		tm = new TourMember(name)
		msg.reply tm.addPicture(picTitle)

	# ツアーの情報をすべて削除する
	robot.hear /tour data clean$/i, (msg) ->
		name = msg.message.user.name
		tm = new TourMember(name)
		tm.deleteTourData()
		msg.reply "tour data deleted."

