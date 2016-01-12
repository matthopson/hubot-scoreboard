# Description
#   Keep score for your team.
#
# Configuration:
#   None
#
# Commands:
#   start a game - Starts a new game.
#   end the game - Ends the current game.
#   give <user> <number> points - Adds points to a user's score.
#   deduct <number> points from <user> - Deducts points from user's score.
#   how many points does <user> have - Checks a user's point count.
#   what's the score - Shows the current score.
#
# Notes:
#   None
#
# Author:
#   Matt Hopson

module.exports = (robot) ->

  unless robot.brain.hasOwnProperty('scoreboard')
    robot.brain.scoreboard =
      highScores: []
      game: {}

  scoreboard = robot.brain.scoreboard

  sortHighestFirst = (a, b) ->
    return -1 if a.points > b.points
    return 1 if a.points < b.points
    return 0 if a.points == b.points

  # Searches users by id or name
  findUser = (search) ->
    foundUser = null

    if typeof search is 'number'
      searchProp = 'id'
    else
      searchProp = 'name'
    for index, user of robot.brain.data.users
      if user[searchProp].toLowerCase() == search.toLowerCase()
        foundUser = user
        break

    return foundUser


  isGameRunning = ->
    return scoreboard.game.isGameRunning

  checkHighScores = (user) ->
    if user? and isGameRunning()
      highScore =
        userName: user.name
        points: user.points
        gameName: scoreboard.game.gameName
        gameId: scoreboard.game.id

      robot.brain.scoreboard.highScores.push(highScore)

    if scoreboard.highScores.length > 0
      # sort our scores
      scoreboard.highScores.sort(sortHighestFirst)

      # Truncate list to 10
      if scoreboard.highScores.length > 10
        scoreboard.highScores.length = 10

      highScoresText = ''
      scoreboard.highScores.forEach (hs, index) ->
        place = index + 1
        highScoresText += "#{place}. `#{hs.userName}` - [#{hs.gameName}] - `#{hs.points}`\n"
    else
      highScoresText = "Sorry, it doesn't look like there are any high scores yet."

    return highScoresText


  # Starts a new game.
  robot.respond /start(?:.*)game:?\s*(?:'|")(.*)(?:'|")/i, (res) ->
    gameName = res.match[1].trim()
    unless isGameRunning()
      if scoreboard.game.id?
        gameId = scoreboard.game.id + 1
      else
        gameId = 1

      robot.brain.scoreboard.game =
        gameName: gameName
        gameId: gameId
        isGameRunning: true

      res.reply "`#{gameName}` has begun! Best of luck to you all."
    else
      res.reply "There is already a game in progress. You must end it before starting a new game."


  # Ends the current game.
  robot.respond /end the game/i, (res) ->
    if isGameRunning()
      robot.brain.scoreboard.game.isGameRunning = false

    # find high score
    highestScoringUser = null
    currentHighScore = 0
    for index, user of robot.brain.data.users
      if user.points?
        scoreboard.highScores.push({userName: user.name, points: user.points, gameName: scoreboard.game.gameName, gameId: scoreboard.game.id})
        if user.points > currentHighScore
          highestScoringUser = user
          currentHighScore = user.points
        # reset to 0
        user.points = 0

    if highestScoringUser?
      winnerText = "With a score of #{currentHighScore} @#{highestScoringUser.name} takes the prize!"
    else
      winnerText = "Nobody scored a single point :("

    # Check for high score
    highScores = checkHighScores()
    highScoresThisGame = scoreboard.highScores.filter (hs) ->
      hs.gameId is scoreboard.game.id

    if highScoresThisGame.length > 0
      highScoresText = "\nNEW HIGH SCORE!\n#{highScores}"
    else
      highScoresText = ""
    res.reply "#{scoreboard.game.gameName} has ended.\n#{winnerText}#{highScoresText}"



  # Adds points to a user's score.
  robot.respond /give @?([a-zA-Z._\-0-9]+)\s([0-9,.]*) (?:point+s?)/i, (res) ->
    unless isGameRunning()
      res.reply "Sorry, but you must start a game before you can do that."
    else
      userName = res.match[1].trim()
      points = res.match[2].trim()

      if userName.charAt(0) is '@'
        userName = userName.substr 1

      user = findUser userName

      unless user.hasOwnProperty('points')
        user.points = 0
      user.points += parseInt(points)

      res.reply "I've given @#{userName} #{points}, bringing their total to #{user.points}."


  # Deducts points from a user's score.
  robot.respond /deduct ([0-9,.]*) (?:point+s?) from @?([a-zA-Z._\-0-9]+)/i, (res) ->
    unless isGameRunning()
      res.reply "Sorry, but you must start a game before you can do that."

    points = res.match[1].trim()
    userName = res.match[2].trim()

    if userName.charAt(0) is '@'
      userName = userName.substr 1

    user = findUser userName

    unless user.hasOwnProperty('points')
      user.points = 0
    user.points -= parseInt(points)

    res.reply "I've deducted #{points} points from @#{userName}, bringing their total to #{user.points}."



  # Checks a user's point count.
  robot.respond /how many points does @?([a-zA-Z._\-0-9]+) have/i, (res) ->
    unless isGameRunning()
      res.reply "Sorry, but you must start a game before you can do that."

    userName = res.match[1].trim()

    if userName.charAt(0) is '@'
      userName = userName.substr 1

    user = findUser userName

    unless user.hasOwnProperty('points')
      user.points = 0

    res.reply "@#{userName} currently has #{user.points} points."


  # Display current score
  robot.respond /(what\'s|what is)(.*)score/i, (res) ->
    unless isGameRunning()
      res.reply "Sorry, but you must start a game before you can do that."

    # Create an array of user scores
    userScores = []
    for index, user of robot.brain.data.users
      if user.hasOwnProperty('points')
        userScores.push user

    if userScores.length > 0
      userScores.sort(sortHighestFirst)
      currentScoreText = ''
      userScores.forEach (userScore, index) ->
        place = index + 1
        currentScoreText += "#{place}. `#{userScore.name}` with `#{userScore.points}` points.\n"
    else
      currentScoreText = "Sorry, but there doesn't seem to be any points acrued this game."

    res.reply "Here is the score for `#{scoreboard.game.gameName}`:\n #{currentScoreText}"
