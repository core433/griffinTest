class @SessionHost

  constructor: (@game) ->
    # XXX sessionid is very important.  A unique sessionid should be assigned
    # to each human player in a multiplayer game, and the other players'
    # sessionids must be kept hidden on the server.  When the server sends
    # commands to the server, they must send their sessionid for verification.
    # The server then processes the command if the player's sessionid matches
    # that of the active player.  In fact, if the player's sessionid does not
    # match the in-game player's, don't send anything to the server at all to
    # conserve bandwidth.
    @sessionid = null
    @players = []   # array of Player objects
    @bullets = []
    @active_player = null
    @game_time_remaining = 0

    # Add all sprites in play to this group so that the GameUI's group sits
    # on top of all of them
    @playgroup = null

    # p2.js world which runs our physics simulation
    @p2world = null

    # game camera
    @gcamera = null

    @gameOver = false

  initialize: (player_configs) ->

    GameInputs.shost = this
    GameInputs.setupInputs()
    GameUI.initialize(this)
    
    # for particle physics
    @game.physics.startSystem(Phaser.Physics.ARCADE)

    # Setup background and world
    @playgroup = @game.add.group()
    @background = new Phaser.Sprite(@game, 0, 0, 'background')
    @background.body = null
    @playgroup.add(@background)
    @game.camera.scale.set(
      GameConstants.cameraScale,GameConstants.cameraScale)

    # This is our own game logic World class, not to be confused with
    # Phaser's built in @game.world
    @world = WorldCreator.loadFromImage(this, 'world_divide')
    @world.setSpawnOrder([2,0,1,3])
    console.log @world.spawnOrder
    # world will set bounds of the game, from that need to set background
    # scale to the max scale of world bounds
    bgX = @game.world.width / @background.width / GameConstants.cameraScale
    bgY = @game.world.height / @background.height / GameConstants.cameraScale
    @background.scale.set(bgX, bgY)

    # This is the p2 physics simulated world, which is where the
    # physics representations of the players and bullets etclive.
    # p2world holds the ground truth of where objects in the scene
    # live, we only use Phaser for drawing sprites at their locations.
    @p2world = new p2.World()
    @p2world.gravity = [0,0]

    num_players = 0
    for config in player_configs
      id = config.id
      name = config.name
      spawnXY = @world.getSpawnForPlayerNum(num_players)
      if spawnXY == null
        num_players++
        continue
      # instantiate player objects and add to @players list
      player = new Player(this)
      player.initialize(this, id, spawnXY[0], spawnXY[1],
        GameConstants.playerScale, 0)
      player.initHealth(200)
      player.setName(name)
      @players.push player

      num_players++

    #GameUI.updateTurnText('Player ' + next_player_id + ' turn')
    @game_time_remaining = GameConstants.turnTime

    # Disable player-to-player p2 body collisions.  For every pairing of 
    # players, disable collisions
    if num_players > 1
      i = 0
      while true
        for j in [i..num_players-1]
          if j != i
            #console.log 'disable ', i, ' ', j
            @p2world.disableBodyCollision(@players[i].entity.p2body, @players[j].entity.p2body)
        i += 1
        if i == num_players
          break

    @gcamera = new GameCamera(this)
    @gcamera.initialize(1.0)
    @active_player = @players[0]
    @active_player.active = true
    @active_player.showUI()
    @refreshUI()
    @gcamera.follow(@active_player.sprite)
    @gcamera.easeTo(@active_player.getX() - @game.width/2, @active_player.getY() - @game.height/2)


    GameUI.bringToTop()

    #@game.input.keyboard.addKey(Phaser.Keyboard.SPACEBAR).onDown.add(@playerFire, this)
    #@game.input.keyboard.addKey(Phaser.Keyboard.Z).onDown.add(@toggleZoom, this)

  update: (dt) ->

    # step p2world for physics simulation to occur
    @p2world.step(dt)
    
    if @gameOver
      return

    for player in @players
      player.update(dt, @world)

    for bullet in @bullets
      if bullet != null
        bullet.update(@world)

    @gcamera.update(dt)

    if @game_time_remaining > 0
      oldtime = Math.floor(@game_time_remaining)
      @game_time_remaining -= dt
      newtime = Math.ceil(@game_time_remaining)
      if oldtime != newtime
        GameUI.updateTurnTime(newtime)
      if @game_time_remaining <= 0
        GameUI.updateTurnTime(0)

    if @active_player == null
      return

    GameInputs.update(dt)

    GameUI.updateMoveBar(
      @active_player.cur_move_points / @active_player.max_move_points)
    GameUI.updateShotBar(
      @active_player.cur_shot_points / @active_player.max_shot_points)

  render: ->
    @world.render()

  playerMoveLeft: (dt) ->
    @gcamera.follow(@active_player.sprite)
    @active_player.moveLeft(dt, @world)
  playerMoveRight: (dt) ->
    @gcamera.follow(@active_player.sprite)
    @active_player.moveRight(dt, @world)
  playerAimUp: (dt) ->
    #@gcamera.follow(@active_player.sprite)
    @active_player.aimUp(dt)
  playerAimDown: (dt) ->
    #@gcamera.follow(@active_player.sprite)
    @active_player.aimDown(dt)
  playerChargeShot: (dt) ->
    #@gcamera.follow(@active_player.sprite)
    @active_player.chargeShot(dt)
    GameUI.updateChargeBar(
      @active_player.cur_charge / @active_player.max_charge)
  playerFire: () ->
    #@gcamera.follow(@active_player.sprite)
    @active_player.fire()
    GameUI.updateChargeBar(0)
    GameUI.refreshChargeSave(@active_player.last_charge / @active_player.max_charge)
    GameInputs.spaceIsDown = false
    GameUI.refreshWeaponUI(@active_player.wep_num)
  playerMoveCamera: (x, y) ->
    @gcamera.playerMoveCamera(x, y)
  playerReleaseCamera: () ->
    @gcamera.playerReleaseCamera()
  playerSetWeapon: (num) ->
    # XXX Currently implementation won't work for multiplayer.  Need to 
    # associate Player objects with sessionid of human players, then set the
    # Player with corresponding human sessionid's weapon.
    # For now just set active player while it's "single player"
    if @active_player == null
      return
    @active_player.setWeapon(num)

  refreshUI: ->
    GameUI.updateMoveBar(
      1.0 - @active_player.cur_movement / @active_player.max_movement)
    GameUI.updateChargeBar(0)
    GameUI.refreshChargeSave(@active_player.last_charge / @active_player.max_shot_charge)
    GameInputs.spaceIsDown = false
    GameUI.refreshWeaponUI(@active_player.wep_num)

  removePlayer: (removePlayer) ->
    if @active_player == removePlayer
      @active_player = null
    # first remove reference to player
    remaining_players = []
    for player in @players
      if player != removePlayer
        remaining_players.push(player)
    @players = remaining_players

    if @players.length == 1
      @gameOver = true
      @gameOverText = new Phaser.Text(@game, 200, 200, 'Game Over')
      @gcamera.addFixedSprite(@gameOverText)
      return

  removeBullet: (removeBullet) ->
    remaining_bullets = []
    for bullet in @bullets
      if bullet != removeBullet
        remaining_bullets.push(bullet)      
    @bullets = remaining_bullets
    

    


