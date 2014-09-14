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
	class Tour
		_tourData = []
		getTourData = ->
			console.log "loading correct data..."
			request.get(options, (error, response, body) ->
				if !error && response.statusCode == 200
					_tourData = body
					console.log "data loading finished."
				else
					console.log 'error: '+ response.statusCode;
			)
		getTourData()

		constructor: ->
			
		# 与えられたタイトルの写真が正解かどうか
		@isCorrectPicture = (title) ->
			correctPics = _tourData.correctPics
			pics = ( pic for pic in correctPics when pic.title is title )
			return true if pics.length > 0
			false

		@getTeam = (teamName) ->
			team for team in _tourData.team when team.name is teamName

	class TourTeam
		constructor: (teamName)->
			@getMembers = ->
				( new TourMember(userName) for userName in _teamData.member )

			@getPictures = ->
				teamPics = []
				for member in _members
					for memberPic in member.getPictures()
						# teamPicsにまだ追加していない写真をならば追加
						teamPics.push pic if ( teamPic for teamPic in teamPics when teamPic is memberPic ).length is 0
				teamPics

			@getPicturesnum = ->
				@getPictures().length

			@getCorrectPictures = ->
				( cpic for cpic in @getPictures() when cpic.isCorrect )

			@getCorrectPicturesNum = ->
				@getCorrectPictures().length
			_teamData = Tour.getTeam(teamName)
			_members = @getMembers()

	# 撮った写真
	class Picture
		constructor: (title) ->
			_title = title
			_date = new Date()
			_isCorrect = Tour.isCorrectPicture title
			
			# public method
			@getTitle = ->
				_title
			
			@toObject = ->
				{title:_title, date:_date, isCorrect:_isCorrect}

	# ユーザーごとに保持する情報
	class TourMember
		constructor: (name) ->
			# ---- private instance field/method ----
			_userDB = null
			
			# 指定されたrobot.brain.user内のデータを初期化する
			_dbInitialize = ->
				_userDB.pics = _userDB.pics or []
			# ---- private instance field/method ----
			
			# ---- public method ----
			@getPictures = ->
				_userDB.pics
			
			@getPicturesNum = ->
				_userDB.pics.length

			@getCorrectPictures = ->
				( pic for pic in _userDB.pics when pic.isCorrect is true )

			@getCorrectPicturesNum = ->
				( pic for pic in _userDB.pics when pic.isCorrect is true ).length

			# 与えられたタイトルの写真を追加する.
			# まだ撮影していないタイトルであればture、既に撮影していればfalseを返す
			@addPicture = (title) =>
				newPic = new Picture(title)
				pics = ( pic for pic in _userDB.pics when pic.title is newPic.getTitle() )
				if pics.length > 0
					return "#{pics[0].title} という名前の写真は既に存在します。"
				newPicObj = newPic.toObject()
				_userDB.pics.push newPicObj
				"写真名「#{newPic.getTitle()}」を受け付けました。#{newPicObj.isCorrect}"
			# ---- public method ----
			
			@deleteTourData = ->
				console.log _userDB.pics
				_userDB.pics = [] # tourごと{}で置き換えようとすると失敗するので注意
		 
			# constroctor
			users = robot.brain.usersForFuzzyName(name)
			if users.length > 1
				msg.send getAmbiguousUserText users
				return
			else if users.length is 0
				msg.send "#{name}というユーザーはいません。"
				return
			
			users[0].tour = users[0].tour or {} 
			_userDB = users[0].tour
			_dbInitialize.call @

	# hubot起動時に保存する変数たち



	# 指定されたタイトルの写真を追加する
	robot.hear /pic (.*)$/i, (msg) ->
		picTitle = msg.match[1]
		name = msg.message.user.name
		tm = new TourMember(name)
		msg.reply tm.addPicture(picTitle)

	robot.hear /status$/i, (msg) ->
		name = msg.message.user.name
		tm = new TourMember(name)
		rep = "pics: #{tm.getPictures()}\n"
		rep += "picsNum: #{tm.getPicturesNum()}\n"
		rep += "correctPics: #{tm.getCorrectPictures()}\n"
		rep += "correctPicsNum: #{tm.getCorrectPicturesNum()}\n"
		msg.reply rep

	robot.hear /teamA status$/i, (msg) ->
		team = new TourTeam "teamA"
		rep = "pics: #{team.getPictures()}\n"
		rep += "picsNum: #{team.getPicturesNum()}\n"
		rep += "correctPics: #{team.getCorrectPictures()}\n"
		rep += "correctPicsNum: #{team.getCorrectPicturesNum()}\n"
		msg.reply rep

	# ツアーの情報をすべて削除する
	robot.hear /tour data clean$/i, (msg) ->
		name = msg.message.user.name
		tm = new TourMember(name)
		tm.deleteTourData()
		msg.reply "tour data deleted."
