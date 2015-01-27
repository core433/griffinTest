class @ExplosionFactory

  @createExplosionBasic: (game, x, y, scale=1) ->
    blasts = @createBlastBasic(game, x, y, scale)
    sparks = @createSparksBasic(game, x, y, scale)
    #glow = @createGlowBasic(game, x, y, scale)
    rings = @createRingBasic(game, x, y, scale)
    return blasts.concat(sparks.concat(rings))

  # A tumbling red orange yellow direct blast explosion, part normal blend,
  # part add blend (bright)
  @createBlastBasic: (game, x, y, scale=1) ->
    # ============================
    # Explosion blast
    numBlasts = 1
    blastLifetimeMs = 900
    blastAEmitter = game.add.emitter(x, y, numBlasts)
    blastAEmitter.blendMode = Phaser.blendModes.NORMAL
    blastAEmitter.makeParticles('explosion')
    blastAEmitter.gravity = 0
    blastAEmitter.setXSpeed(-20*scale, 20*scale)
    blastAEmitter.setYSpeed(-10*scale, -20*scale)
    blastAEmitter.setAlpha(1.0, 0.0, blastLifetimeMs, Phaser.Easing.Quintic.In)
    blastAEmitter.setScale(0.8*scale, 1.6*scale, 0.8*scale, 1.6*scale, 
        blastLifetimeMs, Phaser.Easing.Linear.In)
    blastAEmitter.setRotation(400, 600)
    # explode, lifespan (ms), frequency, quantity, forceQuantity
    blastAEmitter.start(false, blastLifetimeMs, 60, numBlasts)

    """
    blastEmitter = game.add.emitter(x, y, numBlasts)
    blastEmitter.blendMode = Phaser.blendModes.ADD
    blastEmitter.makeParticles('explosion')
    blastEmitter.gravity = -80*scale
    blastEmitter.setXSpeed(-60*scale, 60*scale)
    blastEmitter.setYSpeed(-20*scale, -40*scale)
    blastEmitter.setAlpha(0.8, 0, blastLifetimeMs, Phaser.Easing.Linear.In)
    blastEmitter.setScale(1.8*scale, 0.2*scale, 1.8*scale, 0.2*scale, 
        blastLifetimeMs, Phaser.Easing.Linear.In)
    # explode, lifespan (ms), frequency, quantity, forceQuantity
    blastEmitter.start(false, blastLifetimeMs, 60, numBlasts)

    return [blastAEmitter, blastEmitter]
    """
    return [blastAEmitter]

  # Flying sparks exploding from a single point
  @createSparksBasic: (game, x, y, scale=1, sprite='spark') ->
    numSparks = 32*scale
    sparkLifetimeMs = 1200
    sparkEmitter = game.add.emitter(x, y, numSparks)
    sparkEmitter.blendMode = Phaser.blendModes.ADD
    sparkEmitter.makeParticles(sprite)
    sparkEmitter.gravity = 300*scale
    sparkEmitter.setXSpeed(-200*scale, 200*scale)
    sparkEmitter.setYSpeed(-300*scale, 100*scale)
    sparkEmitter.setAlpha(1, 0.1, sparkLifetimeMs, Phaser.Easing.Quintic.In)
    sparkEmitter.setScale(1.2*scale, 0.6*scale, 1.2*scale, 0.6*scale, 
        sparkLifetimeMs, Phaser.Easing.Quintic.In)
    sparkEmitter.setRotation(0, 400)
    # explode, lifespan (ms), frequency, quantity, forceQuantity
    sparkEmitter.start(true, sparkLifetimeMs, null, numSparks)

    return [sparkEmitter]

  # Large lingering glow
  @createGlowBasic: (game, x, y, scale=1, timescale=1) ->
    numGlow = 1
    glowLifetimeMs = 3000 * timescale
    glowEmitter = game.add.emitter(x, y, numGlow)
    glowEmitter.blendMode = Phaser.blendModes.ADD
    glowEmitter.makeParticles('glow')
    glowEmitter.gravity = 0
    glowEmitter.setXSpeed(-0, 0)
    glowEmitter.setYSpeed(-0, 0)
    glowEmitter.setRotation(0,0)
    glowEmitter.setAlpha(0.6, 0, glowLifetimeMs, Phaser.Easing.Linear.In)
    glowEmitter.setScale(10*scale, 8*scale, 10*scale, 8*scale, 
        glowLifetimeMs, Phaser.Easing.Linear.In)
    # explode, lifespan (ms), frequency, quantity, forceQuantity
    glowEmitter.start(true, glowLifetimeMs, null, numGlow)

    return [glowEmitter]

  # Large expanding ring
  @createRingBasic: (game, x, y, scale=1) ->
    numRing = 1
    ringLifetimeMs = 800
    ringEmitter = game.add.emitter(x, y, numRing)
    ringEmitter.blendMode = Phaser.blendModes.ADD
    ringEmitter.makeParticles('ring')
    ringEmitter.gravity = 0
    ringEmitter.setXSpeed(-0, 0)
    ringEmitter.setYSpeed(-0, 0)
    ringEmitter.setRotation(0,0)
    ringEmitter.setAlpha(0.8, 0, ringLifetimeMs, Phaser.Easing.Linear.Out)
    ringEmitter.setScale(2*scale, 7*scale, 2*scale, 7*scale, 
        ringLifetimeMs, Phaser.Easing.Linear.Out)
    # explode, lifespan (ms), frequency, quantity, forceQuantity
    ringEmitter.start(true, ringLifetimeMs, null, numRing)

    return [ringEmitter]

  @createFlareBasic: (game, x, y, scale=1) ->
    numFlare = 1
    flareLifetimeMs = 1000
    flareEmitter = game.add.emitter(x, y, numFlare)
    flareEmitter.blendMode = Phaser.blendModes.ADD
    flareEmitter.makeParticles('flare')
    flareEmitter.gravity = 0
    flareEmitter.setXSpeed(-0, 0)
    flareEmitter.setYSpeed(-0, 0)
    flareEmitter.setRotation(0,0)
    flareEmitter.minParticleScale = 6*scale
    flareEmitter.maxParticleScale = 6*scale
    flareEmitter.setAlpha(0.7, 0, flareLifetimeMs, Phaser.Easing.Linear.Out)
    #flareEmitter.scale = 10
    #flareEmitter.setScale(10, 10, 10, 10, flareLifetimeMs, Phaser.Easing.Linear.Out)
    # explode, lifespan (ms), frequency, quantity, forceQuantity
    flareEmitter.start(true, flareLifetimeMs, null, numFlare)

    return [flareEmitter]

  @createPebbleBasic: (game, x, y, scale=1) ->
    numPebble = 16*scale
    pebbleLifetimeMs = 1200
    pebbleEmitter = game.add.emitter(x, y, numPebble)
    pebbleEmitter.setSize(40*scale,40*scale)
    pebbleEmitter.blendMode = Phaser.blendModes.NORMAL
    pebbleEmitter.makeParticles('pebble')
    pebbleEmitter.gravity = 800*scale
    pebbleEmitter.setXSpeed(-200*scale, 200*scale)
    pebbleEmitter.setYSpeed(-400*scale, -100*scale)
    pebbleEmitter.minParticleScale = 0.3*scale
    pebbleEmitter.maxParticleScale = 1.0*scale
    pebbleEmitter.setAlpha(1.0, 0.2, pebbleLifetimeMs, Phaser.Easing.Quintic.In)
    #pebbleEmitter.scale = 10
    #pebbleEmitter.setScale(10, 10, 10, 10, pebbleLifetimeMs, Phaser.Easing.Linear.Out)
    # explode, lifespan (ms), frequency, quantity, forceQuantity
    pebbleEmitter.start(true, pebbleLifetimeMs, null, numPebble)

    return [pebbleEmitter]

  @createSmokeTrailBasic: (game, x, y, scale=1, timescale=1, sprite='smoke', add=false) ->
    numSmoke = 30 * timescale
    smokeLifetimeMs = 1400 / timescale
    smokeEmitter = game.add.emitter(x, y, numSmoke)
    smokeEmitter.setSize(50*scale,50*scale)
    smokeEmitter.makeParticles(sprite)
    if add
        smokeEmitter.blendMode = Phaser.blendModes.ADD
    smokeEmitter.gravity = -80*scale
    smokeEmitter.setXSpeed(-60*scale, 60*scale)
    smokeEmitter.setYSpeed(-60*scale, 60*scale)
    smokeEmitter.setAlpha(0.8, 0, smokeLifetimeMs, Phaser.Easing.Cubic.In)
    smokeEmitter.setScale(0.5*scale, 1.0*scale, 0.5*scale, 1.0*scale, 
        smokeLifetimeMs, Phaser.Easing.Linear.In)
    # explode, lifespan (ms), frequency, quantity, forceQuantity
    smokeEmitter.start(false, smokeLifetimeMs, 180/timescale, numSmoke)

    return [smokeEmitter]

  @createRedHPTextBasic: (game, x, y, num) ->
    hp_text = game.add.bitmapText(
      0, 
      0, 'rednum', num.toString(), 32)
    hp_image = game.add.sprite(x, y, null)
    hp_image.addChild(hp_text)
    tween = game.add.tween(hp_image)
    xW = 0.12 * game.width
    yH = 0.12 * game.height
    xrand = Math.random() * xW - xW/2
    yrand = Math.random() * -yH*0.7 - yH*0.3
    tween.to({x: x+xrand, y: y+yrand}, 1200)
    tween.easing(Phaser.Easing.Cubic.Out)
    tween.start()
    game.time.events.add(1200, hp_image.destroy, hp_image)
    game.time.events.add(1200, hp_text.destroy, hp_text)

  




