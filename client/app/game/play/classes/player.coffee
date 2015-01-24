class @Player

  # XXX This is hacky for testing. Player shouldn't be controlling
  #     their own movement

  constructor: (@shost) ->
    # display and ui
    @sprite = null
    @id = null
    @nametext = null
    @nameoffX = 0
    @nameOffY = 0

    # gameplay and stats
    @active = false
    @entity = null
    @maxhealth = 200
    @curhealth = 200
    @healthsprite = null
    @healthbarsprite = null
    @aimspeed = 70
    @speed = 25
    @max_move_points = 200 # total number of move points
    @cur_move_points = 200 # current number of move ments
    @move_recharge_rate = 10    # how many move points recharges per second
    @move_deplete_rate = 14     # how many move points depleted per second
    @teleport_deplete_rate = 80

    @max_movement = 200
    @facingLeft = true

    # firing and charging shot
    @wep_num = 0
    @reticule = null
    @can_fire = false

    @max_shot_points = 200
    @cur_shot_points = 200
    @shot_recharge_rate = 12
    @shot_deplete_rate = 100

    @charge_rate = 420
    @cur_charge = 0
    @max_charge = 1100
    @last_charge = 0        # used to show last shot strength indicator

    # Specifies a dictionary of delay times and bullets to create with their
    # stats to pass to BulletFactory
    @bulletQueue = []
    # keeps track of how many bullets fired by this player are still alive
    @liveBulletsThisRound = 0
    
  initialize: (@shost, @id, x, y, @scale=1, rot=0) ->
    @sprite = new PlayerSprite(@shost.game, x, y, 'player')
    @sprite.angle = rot
    @sprite.scale.x = @scale
    @sprite.scale.y = @scale
    @sprite.body = null
    @shost.playgroup.add(@sprite)

    # Create physics entity
    @entity = new Entity(@shost)
    # XXX previz is for showing collision logic to ground
    #previzW = 2*GameConstants.playerBaseCollisionTiles * @shost.world.tileSize
    #previzH = (GameConstants.playerSideCollisionStartY) * @shost.world.tileSize
    #@entity.initialize(x, y, previzW, previzH, 0, -previzH/2)
    @entity.initialize(x,y,70*@scale,100*@scale,0,-50*@scale)
    @shost.p2world.addBody(@entity.p2body)

    # Create reticule for aiming
    @reticule = new Reticule(this)
    # XXX should resolve these from the mount type's cannon location, which
    # should be a % of the sprite's width and height
    cannonXOff = 50*@scale
    cannonYOff = -40*@scale
    @reticule.initialize(cannonXOff, cannonYOff, 40, 0, 0.6)
    @reticule.setMaxAim(70)
    @reticule.setMinAim(10)

    if GameConstants.debug
      @entity.initPreviz(@shost.game)

  setName: (name) ->
    @nametext = new Phaser.BitmapText(@shost.game, 0, 0, 'bitfont', name, 14)
    @nameoffX = -@nametext.width / 2
    @nameoffY = -@sprite.height - 0.02 * @shost.game.height
    @shost.playgroup.addChild(@nametext)

  # ============================================================================
  #                             HEALTH AND DEATH
  # ============================================================================
  initHealth: (maxhealth) ->
    hscalex = maxhealth/GameConstants.healthBase
    @maxhealth = maxhealth
    @curhealth = maxhealth
    @healthbarsprite = new Phaser.Sprite(@shost.game, 0, 0, 'healthbar')
    @healthbarsprite.angle = 0
    @healthbarsprite.scale.x = hscalex
    @healthbarsprite.scale.y = 1.0
    @healthbarsprite.anchor =
      x: 0.0
      y: 0.5
    @healthbarsprite.x = -@healthbarsprite.width/2
    @healthbarsprite.y = 10
    @healthsprite = new Phaser.Sprite(@shost.game, 0, 0, 'health')
    @healthsprite.angle = 0
    @healthsprite.scale.x = hscalex
    @healthsprite.scale.y = 1.0
    @healthsprite.anchor =
      x: 0.0
      y: 0.5
    @healthsprite.x = -@healthsprite.width/2
    @healthsprite.y = 10
    @sprite.addChild(@healthbarsprite)
    @sprite.addChild(@healthsprite)

  addHealth: (health) ->

    health = Math.ceil(health)
    if health == 0
      return

    @curhealth += health
    @curhealth = GameMath.clamp(@curhealth, 0, @maxhealth)
    @healthsprite.scale.x = @curhealth / GameConstants.healthBase

    ExplosionFactory.createRedHPTextBasic(
      @shost.game, 
      @getX(), 
      @getY() - @sprite.height/2/@sprite.scale.y,
      health)

    if @curhealth <= 0
      @die()

  die: () ->
    if GameConstants.debug
        console.log 'player died'
    @sprite.destroy(true)
    @sprite = null
    @nametext.destroy(true)
    @nametext = null
    @entity.kill()
    @entity = null
    @reticule.kill()
    @reticule = null
    @healthbarsprite.destroy(true)
    @healthbarsprite = null
    @healthsprite.destroy(true)
    @healthsprite = null
    if @active
      # if player is active player, endTurn will remove the player from game
      @endTurn(true)
    else
      # otherwise manually remove player from game right now
      @shost.removePlayer(this)

  # ============================================================================
  #                             WEAPONS AND FIRING
  # ============================================================================
  setWeapon: (num) ->
    @wep_num = num
    @cur_charge = 0

  aimUp: (dt) ->
    aimChange = @aimspeed * dt
    @reticule.addAimAngle(aimChange)
    @reticule.update(@sprite.x, @sprite.y)

  aimDown: (dt) ->
    aimChange = @aimspeed * dt
    @reticule.addAimAngle(-aimChange)
    @reticule.update(@sprite.x, @sprite.y)

  chargeShot: (dt) ->

    movement = false

    # weapon #2 is teleport for now
    if @wep_num == 2
      movement = true

    if movement
      shot_cost = @teleport_deplete_rate * dt
      if shot_cost > @cur_move_points
        shot_cost = @cur_move_points
      @cur_move_points -= shot_cost
      addCharge = @charge_rate * shot_cost / @teleport_deplete_rate
    else
      shot_cost = @shot_deplete_rate * dt
      if shot_cost > @cur_shot_points
        shot_cost = @cur_shot_points
      @cur_shot_points -= shot_cost
      addCharge = @charge_rate * shot_cost / @shot_deplete_rate

    @last_charge = @cur_charge
    @cur_charge += addCharge
    @cur_charge = GameMath.clamp(@cur_charge, 1, @max_charge)

  spawnBullet: (spec) ->

    bullet = new Bullet(@shost)
    rorg = @reticule.getOrigin()

    dirSign = 1
    angle = @reticule.aimAngle
    if @facingLeft
      dirSign = -1
      angle = 180 - @reticule.aimAngle

    # XXX affected by wind, etc
    fx = 0
    fy = GameConstants.gravity
    # since we've zeroed @cur_charge when calling fire(), 
    # use stored @last_charge instead
    vel = @last_charge
    bullet.initialize(
      this, 
      @getX() + dirSign *rorg[0], @getY() + rorg[1], 
      vel, angle, 
      fx, fy, 
      spec)
    
    @shost.bullets.push(bullet)
    #@shost.gcamera.follow(bullet.sprite)

  updateBullets: (dt) ->
    if @bulletQueue.length <= 0
      return
    newQueue = []
    for bulletSpec in @bulletQueue
      newSpec = {}
      delay = bulletSpec.delay
      if delay <= 0
        @spawnBullet(bulletSpec.bullet)
      else
        newSpec.delay = delay - dt
        newSpec.bullet = bulletSpec.bullet
        newQueue.push(newSpec)
    @bulletQueue = newQueue

  recharge: (dt) ->
    @cur_move_points += @move_recharge_rate * dt
    if @cur_move_points > @max_move_points
      @cur_move_points = @max_move_points
    @cur_shot_points += @shot_recharge_rate * dt
    if @cur_shot_points > @max_shot_points
      @cur_shot_points = @max_shot_points

  update: (dt, world) ->
    @recharge(dt)
    
    moved = @entity.update()

    @checkWorldCollision(world)

    # update the sprite to the ground truth simulated position
    @sprite.x = @entity.x
    @sprite.y = @entity.y

    if @getY() > @shost.world.gameYBound
      @die()
      return

    if moved
      @reticule.update(@sprite.x, @sprite.y)
      @nametext.x = @sprite.x + @nameoffX
      @nametext.y = @sprite.y + @nameoffY

    @updateBullets(dt)

  fire: () ->
    if !@can_fire
      return
    #console.log 'FIRE AWAY!'

    # bulletSpecs looks like this:
    # { delay: 1000 (ms),
    #   bullet: {img: 'imagename'}
    # }
    # Note that we want bullet specs returned, not actual bullets, so that
    # they can be fired with delay
    @bulletQueue = BulletSpecFactory.getBulletSpec(@wep_num)
    # do this accounting at the start of firing, rather than waiting for
    # bulletSpawn, or might prematurely end if e.g., the first bullet explodes
    # too soon
    @liveBulletsThisRound = @bulletQueue.length
    # It is up to update() to update the bulletQueue and spawn bullets

    #@can_fire = false
    @last_charge = @cur_charge
    @cur_charge = 0

  # ============================================================================
  #                           MOVEMENT AND FALLING
  # ============================================================================
  makeFall: () ->
    @entity.p2body.force[1] = 2000

  clampToGround: (world) ->
    @entity.p2body.force[1] = 0
    @entity.p2body.velocity[1] = 0
    tileX = world.xTileForWorld(@getX())
    tileY = world.yTileForWorld(@getY())
    highestNonFreeTileY = world.highestNonFreeYTile(tileX, tileY)
    # if height is walkable, clamp it
    if highestNonFreeTileY > tileY - GameConstants.maxWalkableY
      @entity.p2body.position[1] = world.yWorldForTile(highestNonFreeTileY+1)
    
  checkWorldCollision: (world) ->

    # For the bottom 5 world tiles, check rgba
    # starting from center, 1 left, 1 right, 2 left, 2 right
    # if any are on solid ground, don't make fall and clamp to that one
    shouldFall = true
    checkNeighborTiles = [0]
    for i in [1 .. GameConstants.playerBaseCollisionTiles]
      checkNeighborTiles.push(-i)
      checkNeighborTiles.push(i)
    for i in checkNeighborTiles
      tile_rgba = world.getRgbaForWorldXY(@getX(), @getY())
      if world.isGround(tile_rgba)
        @clampToGround(world)
        shouldFall = false
        break
    if shouldFall
      @makeFall()

  # HACKY, use enums for direction
  changeDirection: (faceLeft) ->
    if faceLeft
      @sprite.scale.x = @scale
      @facingLeft = true
      @healthsprite.anchor.x = 0
      @healthsprite.x = -@healthbarsprite.width/2
    else
      @sprite.scale.x = -@scale
      @facingLeft = false
      @healthsprite.anchor.x = 1
      @healthsprite.x = @healthbarsprite.width/2
    @reticule.changeDirection(faceLeft)
    @reticule.update(@sprite.x, @sprite.y)

  initTurn: ->
    if !@active
      return
    console.log @getX()
    console.log @getY()
    @can_fire = true
    @cur_charge = 0

  hasAliveBullets: () ->
    if @liveBulletsThisRound > 0
      return true
    return false
    """
    for bullet in @shost.bullets
      if bullet.player == this
        return true
    return false
    """

  # When a bullet dies, it will try to end the player's turn.  If the bullet is
  # the last bullet left belonging to the player, then it should end turn,
  # otherwise it shouldn't
  tryBulletEndTurn: () ->
    @liveBulletsThisRound -= 1
    if !@hasAliveBullets()
      @endTurn()

  endTurn: (died=false)->
    if !@active
      return
    @active = false
    @shost.tryEndPlayerTurn(died)
    @can_fire = false

  moveLeft: (dt, world) ->
    @move(dt, world, true)

  moveRight: (dt, world) ->
    @move(dt, world, false)

  move: (dt, world, isLeft=false) ->
    if isLeft
      if not @facingLeft
        @changeDirection(true)
    else
      if @facingLeft
        @changeDirection(false)

    dirSign = 1
    if isLeft
      dirSign = -1

    # First check that the player still has remaning "movement points"
    # in his turn.  If not, don't allow moving.
    if @cur_move_points <= 0
      return

    # If this move will exhaust remaining "movement points", cap it to remaining
    # movement
    spend_move_points = @move_deplete_rate * dt
    if spend_move_points > @cur_move_points
      spend_move_points = @cur_move_points

    try_dist = spend_move_points / @move_deplete_rate * @speed
    if try_dist <= 0
      return

    # =======================================================
    # First try our side checks.
    # 1. The flank collision check position is baseCollisionTiles + 1
    #    For example, if base collision width is 3 tiles to the right from 
    #    center, then at the 4th tile form the "collision column"
    # 2. Use a "collision column" at the flank collision position, starting
    #    from maxWalkableY up, check playerSideCollisionTiles num tiles
    #
    # The below diagram illustrates.
    #   'c' -> bottol collision center
    #   '-' -> baseCollisionTile
    #   '|' -> sideCollisionTile
    #   'G' -> Ground 
    #
    #         |       |
    #         |       |    GGGG
    #         |       |   GGGGGG
    #          ---c---    GGGGGGG
    #      GGGGGGGGGGGGGGGGGGGGG
    tileX = world.xTileForWorld(@getX())
    tileY = world.yTileForWorld(@getY())
    latTileX = tileX + (GameConstants.playerBaseCollisionTiles + 1) * dirSign
    latTileY = tileY - GameConstants.playerSideCollisionStartY
    tile_rgba = world.getRgbaForTileXY(latTileX, latTileY)
    if world.isGround(tile_rgba)
      return

    # =======================================================
    # Now see if the new position is walkable
    # 1. Check where the movement would take us if performed.
    # 2. If the terrain is air, let us walk
    # 3. If the terrain is ground, check if it is walkable by seeing if the
    #    top Y tile is within maxWalkableY
    # 4. If the terrain is not walkable, find the nearest X tile that is
    #    is walkable within maxWalkableY and clamp the X position there
    # 5. Find actual traversed distance by subtracting dist - actual walked
    #    which might have been clamped
    try_pos = @getX() + try_dist * dirSign
    tile_rgba = world.getRgbaForWorldXY(try_pos, @getY())

    # If new location is walkable, now need to check that there's no 
    # "floating walls" above it that would block lateral traversal
    if world.isAir(tile_rgba)
      actual_dist = try_dist
    else
      tileX = world.xTileForWorld(try_pos)
      tileY = world.yTileForWorld(@getY())
      highestNonFreeTileY = world.highestNonFreeYTile(tileX, tileY)
      # if height is walkable
      if highestNonFreeTileY > tileY - GameConstants.maxWalkableY
        actual_dist = try_dist
      else
        actual_dist = 0

    if actual_dist != 0
      @cur_move_points -= spend_move_points
    @setX(@getX() + actual_dist * dirSign)
    @reticule.update(@sprite.x, @sprite.y)
    @nametext.x = @sprite.x + @nameoffX
    @nametext.y = @sprite.y + @nameoffY

  setX: (newX) ->
    @entity.setX(newX)
    @sprite.x = newX

  getX: ->
    return @entity.x

  setY: (newY) ->
    @entity.setY(newY)
    @sprite.y = newY

  getY: ->
    return @entity.y

  hideUI: () ->
    @reticule.sprite.visible = false

  showUI: () ->
    @reticule.sprite.visible = true

class @PlayerSprite extends Phaser.Sprite
  
  constructor: ->
    super
    @anchor =
      x: 0.5
      y: 1
    # @scale.x = 0.24
    # @scale.y = 0.27