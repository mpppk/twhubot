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

exec = require('child_process').exec

# スクリプト全体で利用可能な変数。初期化はデータロードが終わってから行う
g_tour = null

module.exports = (robot) ->
	class Prize
		_menHas5Prize = false
		_menHas10Prize = false
		_womenHas5Prize = false
		_womenHas10Prize = false
		@getURL = (teamName, correctPicsNum) ->
			if teamName is "men"
				if correctPicsNum is 5 and not _menHas5Prize
					_menHas5Prize = true
					return "pm8xuS"
				if correctPicsNum is 10 and not _menHas10Prize
					_menHas10Prize = true
					return "KtNA5e"
			if teamName is "women"
				if correctPicsNum is 5 and not _womenHas5Prize
					_womenHas5Prize = true
					return "azfCeM"
				if correctPicsNum is 10 and not _womenHas10Prize
					_womenHas10Prize = true
					return "PZCXSX"
			return null

	class Slack
		_url = "http://harvelous-hubot.herokuapp.com/hubot/tw/"
		_option = "--dump-header - "
		@onNewPictureAdded: (userName, title, roomName) ->
			msg = _url + "newpic/"
			msg += "#{userName}/"
			msg += "#{title}/"
			msg += "#{roomName}/"
			console.log "curl #{_option} #{msg}"
			exec("curl #{_option} #{msg}", (err, stdout, stderr) ->
				console.log stdout
			)

		@onCorrectPictureAdded: (userName, title, correctPicsNum, roomName) ->
			msg = _url + "cpic/"
			msg += "#{userName}/"
			msg += "#{title}/"
			msg += "#{correctPicsNum}/"
			msg += "#{roomName}/"
			console.log "curl #{_option} #{msg}"
			exec("curl #{_option} #{msg}", (err, stdout, stderr) ->
				console.log stdout
			)

		@onCorrectPictureOver: (url, roomName) ->
			msg = _url + "cpicover/"
			msg += "#{url}/"
			msg += "#{roomName}/"
			console.log "curl #{_option} #{msg}"
			exec("curl #{_option} #{msg}", (err, stdout, stderr) ->
				console.log stdout
			)

	class TourDB
		_tourData = []

		getTourData = ->
			console.log "loading correct data..."
			request.get(options, (error, response, body) ->
				if !error && response.statusCode == 200
					_tourData = body
					g_tour = new Tour()
					console.log "data loading finished."
				else
					console.log 'error: '+ response.statusCode;
			)
		getTourData()

		# 与えられたタイトルの写真が正解かどうか
		@isCorrectPicture = (title) ->
			correctPics = _tourData.correctPics
			pics = ( pic for pic in correctPics when pic.title is title )
			return true if pics.length > 0
			false

		@getTeamData = (teamName) ->
			teamData for teamData in _tourData.team when teamData.name is teamName

		@getTeamNames = ->
			( teamData.name for teamData in _tourData.team )

	# robot.brain内のツアー情報へのラッパー
	class Tour
		constructor: ->
			getTeams = ->
				teamNames = TourDB.getTeamNames()
				teams = ( new TourTeam teamName for teamName in teamNames )

			@getTeam = (teamName) ->
				team for team in _teams when team.name is teamName

			@getTeamByUser = (userName) ->
				for team in _teams
					if ( member for member in team.getMembers() when member.getName() is userName ).length > 0
						return team

			_teams = getTeams()

	class TourTeam
		constructor: (teamName)->
			# このチームに所属するメンバーのインスタンス配列を返す
			@getMembers = ->
				members = []
				for userName in TourDB.getTeamData(teamName)[0].member
					member = new TourMember(userName)
					members.push(member) if member.isExist()
				members

			# このチームのメンバーが追加した写真の一覧を返す
			@getPictures = ->
				teamPics = []
				for member in _members
					for memberPic in member.getPictures()
						# teamPicsにまだ追加していない写真をならば追加
						if ( teamPic for teamPic in teamPics when teamPic.title is memberPic.title ).length is 0
							teamPics.push memberPic
				teamPics

			# 正解である写真一覧を取得
			@getCorrectPictures = ->
				( cpic for cpic in @getPictures() when cpic.isCorrect )

			# slackで呟くチャンネルを取得
			@getRoomName = ->
				if _teamName is "dev"
					return "conference_room"
				else
					return _teamName

			# 引数の写真を既に撮っているかどうか
			@hasPicture = (title) ->
				pics = @getPictures()
				( pic for pic in pics when pic.title is title ).length > 0

			@getName = ->
				_teamName

			# _teamData = TourDB.getTeamData(teamName)
			_teamName = teamName
			_members = @getMembers()

	# 撮った写真
	class Picture
		constructor: (title) ->
			_title = title
			_date = new Date()
			_isCorrect = TourDB.isCorrectPicture title
			
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
			_name = name
			_isExist = true
			
			# 指定されたrobot.brain.user内のデータを初期化する
			_dbInitialize = ->
				_userDB.pics = _userDB.pics or []
			# ---- private instance field/method ----
			
			# ---- public method ----
			@getPictures = ->
				_userDB.pics
			
			@getName = ->
				_name

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

				# 写真を追加する前にチームがその写真を撮っていたかどうか
				team = g_tour.getTeamByUser(_name)
				teamHasPic = team.hasPicture newPic.getTitle()
				
				_userDB.pics.push newPicObj

				# 新しく写真が追加されたことを通知する
				unless teamHasPic
					Slack.onNewPictureAdded(_name, newPic.getTitle(), team.getRoomName()) # -> userName, title

				# 新しく正解写真が追加されたことを通知する
				cpicsNum = team.getCorrectPictures().length
				if newPicObj.isCorrect and not teamHasPic
					Slack.onCorrectPictureAdded(_name, newPic.getTitle(), cpicsNum, team.getRoomName())

				# 正解写真が一定数以上になったことを通知する
				prizeURL = Prize.getURL(team.getName(), cpicsNum) # -> team name, correct pic num
				if prizeURL isnt null
					Slack.onCorrectPictureOver( prizeURL, team.getRoomName() ) # -> url, room name
					
				"写真名「#{newPic.getTitle()}」を受け付けました。#{newPicObj.isCorrect}"
			# ---- public method ----
			
			@deleteTourData = ->
				console.log _userDB.pics
				_userDB.pics = [] # tourごと{}で置き換えようとすると失敗するので注意
		 
			@isExist = ->
				_isExist

			# constroctor
			users = robot.brain.usersForFuzzyName(name)
			if users.length > 1
				console.log "too many users (#{name})"
				msg.send getAmbiguousUserText users
				_isExist = false
				return
			else if users.length is 0
				console.log "user not found (#{name})"
				_isExist = false
				return
			
			users[0].tour = users[0].tour or {} 
			_userDB = users[0].tour
			_dbInitialize.call @

	# 指定されたタイトルの写真を追加する
	robot.hear /pic (.*)$/i, (msg) ->
		picTitle = msg.match[1]
		name = msg.message.user.name
		tm = new TourMember(name)
		tm.addPicture(picTitle)

	robot.hear /(.*)の写真撮った$/i, (msg) ->
		picTitle = msg.match[1]
		picTitle.slice(0, -6)
		name = msg.message.user.name
		tm = new TourMember(name)
		tm.addPicture(picTitle)

	robot.hear /status$/i, (msg) ->
		name = msg.message.user.name
		tm = new TourMember(name)
		rep = "投稿した写真枚数: #{tm.getPicturesNum()}\n"
		rep += "正解した写真枚数: #{tm.getCorrectPicturesNum()}\n"
		msg.reply rep

	robot.hear /teamst$/i, (msg) ->
		name = msg.message.user.name
		tour = new Tour()
		team = tour.getTeamByUser(name)
		rep = "チームの投稿した写真枚数: #{team.getPictures().length}\n"
		rep += "チームの正解した写真枚数: #{team.getCorrectPictures().length}\n"
		pics = team.getPictures()
		console.log "チーム写真"
		console.log pic for pic in pics
		cpics = team.getCorrectPictures()
		console.log "チーム正解写真"
		console.log cpic for cpic in cpics
		msg.reply rep

	# ツアーの情報をすべて削除する
	robot.hear /tour data clean$/i, (msg) ->
		name = msg.message.user.name
		tm = new TourMember(name)
		tm.deleteTourData()
		msg.reply "tour data deleted."
