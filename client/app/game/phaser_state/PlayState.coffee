class @PlayState extends Phaser.State
	
	# note @game is passed in automatially here because of parent
	# Phaser.State
	constructor: ->
		@curTime = null
		@lastTime = null
		@dt = 0.015         # runs physics at 66.6 fps
		@accumulator = 0.0
		super

	create: ->

		date = new Date()
		@curTime = date.getTime()
		@lastTime = @curTime

		# SessionHost is the main class that holds all the
		# game logic and objects
		@shost = new SessionHost(@game)
		@shost.initialize(
			[
				{id: "1", name: "UnluckyAmbassador"},
				{id: "2", name: "VizualMenace"},
				{id: "3", name: "Gentlemen Killah"}
			],
			@null)

	update: ->

		date = new Date()
		@lastTime = @curTime
		@curTime = date.getTime()

		frameTime = (@curTime - @lastTime) / 1000.0
		@accumulator += frameTime

		while @accumulator >= @dt
			@accumulator -= @dt
			@shost.update(@dt)
		"""
		# XXX decouple this dt time from Phaser for server implementation
		dt = @game.time.physicsElapsed

		@shost.update(dt)
		"""
	render: ->
		@shost.render()
		@shost.game.debug.text(@shost.game.time.fps || '--', 2, 14, "#00ff00");
