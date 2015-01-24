class @Bullet

  constructor: (@shost) ->

    @player = null  # player whom bullet belongs to

    @sprite = null

    @scale = 1
    @rot = 0

    # World collision detection and crater creation
    # These are in pixels, so for collisions against world need to convert
    # to tiles by dividing by world.tileSize
    @collisionRadiusPx = 20
    @craterRadiusPx = 50
    # Damage and explosion damage.  If a direct hit is achieved, the hit player
    # gets directHitDamage applied, but is ignored in the explosion damage.
    # All others hit by indirect explosionRadius will incur linearly decreasing
    # explosionMaxDamage based on percentage distance from explosion center
    @directHitDamage = 33
    # note that explosion radius is based on center of bullet to center of
    # player, so need to add at least player sprite width/2 to account for
    # that extra distance
    @explosionRadius = 70
    @explosionMaxDamage = 30
    @explosionMinDamage = 10
    # how big the drawn explosion sprite is
    @explosionGfxScale = 1

    @particleStart = null
    @particleAttach = null
    # need to manually kill attached emitters when die
    @attachedEmitters = []
    @particleEnd = null

    @isTeleport = false
    @teleportEnd = null

    @entity = null

    @distance_traveled = 0
    @canHitFirer = false

  initialize: (@player, x, y, velocity, angle, @fx, @fy, spec) ->

    @scale = spec.bullet_scale
    @collisionRadiusPx = spec.collisionRadiusPx

    @entity = new Entity(@shost)
    @entity.initialize(x, y, @collisionRadiusPx*2*@scale, @collisionRadiusPx*2*@scale, 0, 0)
    @shost.p2world.addBody(@entity.p2body)
    @entity.p2body.velocity[0] = velocity * Math.cos(GameMath.deg2rad(angle))
    @entity.p2body.velocity[1] = -velocity * Math.sin(GameMath.deg2rad(angle))
    @entity.setForce(fx, fy)

    @initFromSpec(spec)

    if GameConstants.debug
      @entity.initPreviz(@shost.game)

    if @particleStart != null
      @particleStart(@shost.game, x, y)

    if @particleAttach != null
      @attachedEmitters = @particleAttach(@shost.game, x, y)

  initFromSpec: (spec) ->

    @sprite = new Phaser.Sprite(@shost.game, 0, 0, spec.bullet_image)
    @sprite.anchor =
      x: 0.5
      y: 0.5
    @sprite.scale.x = @scale
    @sprite.scale.y = @scale
    @shost.playgroup.add(@sprite)

    @collisionRadiusPx = spec.collisionRadiusPx
    @craterRadiusPx = spec.craterRadiusPx
    @directHitDamage = spec.directHitDamage
    @explosionRadius = spec.explosionRadius
    @explosionMaxDamage = spec.explosionMaxDamage
    @explosionMinDamage = spec.explosionMinDamage
    @explosionGfxScale = spec.explosionGfxScale
    @particleStart = spec.particleStart
    @particleAttach = spec.particleAttach
    @particleEnd = spec.particleEnd
    # teleportation
    @isTeleport = spec.isTeleport
    @teleportEnd = spec.teleportEnd
    if @isTeleport
      @sprite.blendMode = Phaser.blendModes.ADD

  update: (world) ->

    old_pos = [@entity.x, @entity.y]
    @entity.update()
    new_pos = [@entity.x, @entity.y]
    tx = new_pos[0] - old_pos[0]
    ty = new_pos[1] - old_pos[1]
    traveled = Math.sqrt(tx*tx + ty*ty)
    @distance_traveled += traveled
    if !@canHitFirer
      if @distance_traveled > GameConstants.bulletSelfHitDist
        @canHitFirer = true

    # update the sprite to the ground truth simulated position
    @sprite.x = @entity.x
    @sprite.y = @entity.y
    # Update any attached emitters
    for emitter in @attachedEmitters
      emitter.x = @entity.x
      emitter.y = @entity.y

    # update the rotation of the bullet
    angle = Math.acos(ty / traveled)
    dirX = 1
    if (tx > 0)
      dirX = -1    
    @sprite.rotation = dirX*angle + GameMath.PI

    doKillBullet = false
    spawnExplosion = false
    explosionIgnorePlayer = null
    doTeleport = false
    damage = 0

    # ========================================
    # Player collisions
    for player in @shost.players
      if @isTeleport
        continue
      if @entity.collidesWithEntity(player.entity)
        # if hit firer and not yet past self damage distance traveled, continue
        if player == @player && !@canHitFirer
          continue
        @drawExplosion(@entity.x, @entity.y, false)
        player.addHealth(-@directHitDamage)
        spawnExplosion = true
        doKillBullet = true
        explosionIgnorePlayer = player
        # also add a crater centered around bullet
        tileX = GameMath.clamp(world.xTileForWorld(@entity.x), 0, world.width-1)
        tileY = GameMath.clamp(world.yTileForWorld(@entity.y), 0, world.height-1)
        world.createCrater(tileX, tileY, @craterRadiusPx / world.tileSize)
        @shost.gcamera.jolt()
        break

    # ========================================
    # World collisions
    if !doKillBullet && @entity.collidesWithWorld(world)
      # create a crater in world from the center of the bullet
      if GameConstants.debug
        console.log 'Hit Ground'
      @drawExplosion(@entity.x, @entity.y, true)
      tileX = GameMath.clamp(world.xTileForWorld(@entity.x), 0, world.width-1)
      tileY = GameMath.clamp(world.yTileForWorld(@entity.y), 0, world.height-1)
      world.createCrater(tileX, tileY, @craterRadiusPx / world.tileSize)
      doKillBullet = true
      spawnExplosion = true
      if @isTeleport
        doTeleport = true
      else
        @shost.gcamera.jolt()

    # ========================================
    # Spawn explosion, if necessary, which damages players linearly from
    # its epicenter up to @explosionRadius
    if spawnExplosion
      spawnPos = [@entity.x, @entity.y]
      explosionRadiusSq = @explosionRadius * @explosionRadius
      for player in @shost.players
        if player==explosionIgnorePlayer
          continue
        playerPos = [player.getX(), player.getY()]
        dx = playerPos[0] - spawnPos[0]
        dy = playerPos[1] - spawnPos[1]
        distFromExplosionSq = dx*dx + dy*dy
        damageDiff = @explosionMaxDamage - @explosionMinDamage
        dmgFactor = 1.0 - distFromExplosionSq / explosionRadiusSq
        damage = damageDiff * dmgFactor + @explosionMinDamage
        if dmgFactor > 0
          player.addHealth(-damage)

    # If bullet fell too far down, kill it
    if !doKillBullet 
      if @entity.y > @shost.world.gameYBound
        doKillBullet = true
      else if @entity.x < @shost.world.gameXBoundL || @entity.x > @shost.world.gameXBoundR
        doKillBullet = true

    if doTeleport
      @teleportEnd(@player, @entity.x, @entity.y)
      @shost.gcamera.center(@player.sprite)

    if doKillBullet
      if GameConstants.debug
        console.log 'bullet died'
      @shost.removeBullet(this)
      @kill()
      #@player.tryBulletEndTurn()

  kill: () ->
    @sprite.destroy(true)
    @sprite = null
    @entity.kill()
    @entity = null
    for emitter in @attachedEmitters
      if emitter != null
        emitter.on = false
        # kill the emitter in 2 seconds, let particles live for a bit
        @shost.game.time.events.add(2000, emitter.destroy, emitter)
    @attachedEmitters = null

  drawExplosion: (x, y, hitGround) ->
    if @particleEnd != null
      @particleEnd(@shost.game, x, y, hitGround)



