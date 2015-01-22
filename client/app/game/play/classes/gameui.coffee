class @GameUI
  @shost = null
  @ui_group = null        # phaser group to add all the sprites to

  # Bottom action bar, includes background and movement + shot firing
  @action_sprite = null
  @icon_move_sprite = null
  @icon_shot_sprite = null
  @move_bg_bar = null
  @move_anchorX = null
  @shot_bg_bar = null
  @charge_bg_bar = null
  @move_bar = null
  @shot_bar = null
  @charge_bar = null
  @crop_move = null
  @crop_shot = null
  @crop_charge = null
  @charge_max_width = null
  @move_max_width = null
  @shot_max_width = null
  @charge_save = null
  # weapon buttons
  @buttons_wep = []
  @button_wep1 = null
  @button_wep2 = null
  @button_wep3 = null
  @sprites_wep = []
  # turn timer
  #@turn_text = null
  @turn_time_text = null
  
  # Creates and returns a sprite which will be added to the @ui_group
  # @img: name of image file to use for sprite
  # @screenFractionW: The FRACTION of total screen width image should take up
  #  scaleX and scaleY will be calculated based on this
  # @posX, posY: the position, in pixels, to place the sprite
  # @ancX, ancY: the anchor coordinates, 0-1
  # @ screenFractionPadX/Y: The FRACTION of total screen width image should be
  # padded, useful for fine alignment
  @setupSprite: (img, screenFractionW, posX, posY, 
    ancX, ancY,
    screenFractionPadX, screenFractionPadY,
    heightFactor=1.0) ->

    screenW = @shost.game.width
    screenH = @shost.game.height

    sprite = new Phaser.Sprite(
      @shost.game, 0, 0, img)
    sprite.fixedToCamera = true
    sprite.anchor = 
      x: ancX
      y: ancY
    desiredW = screenW * screenFractionW
    scaleFactor = desiredW/sprite.width
    sprite.scale.set( scaleFactor, scaleFactor*heightFactor)
    sprite.cameraOffset.set(
      posX + screenFractionPadX * screenW, 
      posY + screenFractionPadY * screenH)
    @ui_group.add(sprite)
    return sprite

  @setupButton: (imgsheet, screenFractionW, posX, posY,
    ancX, ancY,
    screenFractionPadX, screenFractionPadY,
    callback) ->

    screenW = @shost.game.width
    screenH = @shost.game.height

    button = new Phaser.Button(
      @shost.game,
      0, 0, imgsheet, callback, this, 1, 0, 2)
    button.fixedToCamera = true
    button.anchor =
      x: ancX
      y: ancY
    desiredW = screenW * screenFractionW 
    scaleFactor = desiredW / button.width
    button.scale.set( scaleFactor, scaleFactor )
    button.cameraOffset.set(
      posX + screenFractionPadX * screenW, 
      posY + screenFractionPadY * screenH)
    button.on = false
    @ui_group.add(button)
    return button

  @buttonCallback: (btn) ->
    console.log 'callback'
    console.log btn
    btn.on = !btn.on
    if btn.on
      btn.setFrames(1, 2, 2)
    else
      btn.setFrames( 1, 0, 2)
    #btn.setFrames(1, (btn.on)?2:0, (btn.on)?0:2)
    #btn.frame = (btn.on)?2:0

  @initialize: (@shost) ->

    @ui_group = @shost.game.add.group()

    # add the action UI which the player uses to move and fire
    screenW = @shost.game.width
    screenH = @shost.game.height

    # player action bar
    @setupActionBar()

    # buttons
    @setupWeaponButtons()

    # turn UI
    @setupTurnUI()

  # ============================================================================
  #                           PLAYER ACTION BAR
  # ============================================================================
  @setupActionBar: () ->

    screenW = @shost.game.width
    screenH = @shost.game.height

    screenFractionW = 0.45
    @action_sprite = @setupSprite('actionui', screenFractionW, 
      screenW/2, screenH,
      0.5, 1,
      0, 0,
      1.0)
    screenFractionW = 0.025
    @icon_move_sprite = @setupSprite('icon_move', screenFractionW, 
      screenW/2 - @action_sprite.width/2, 
      @action_sprite.cameraOffset.y - @action_sprite.height,
      0.5, 0.5,
      0.025, 0.025
      )
    @icon_shot_sprite = @setupSprite('icon_shot', screenFractionW,
      screenW/2 - @action_sprite.width/2,
      @action_sprite.cameraOffset.y - @action_sprite.height/2,
      0.5, 0.5,
      0.025, 0.02)
    # ==============================
    # MOVE BAR
    screenFractionW = 0.19
    @move_bg_bar = @setupSprite('bluebar', screenFractionW,
      screenW * (0.5 - screenFractionW), 
      screenH - @action_sprite.height,
      0.0, 0,
      0.01, 0.02,
      1.6)
    @move_bg_bar.alpha = 0.3
    @move_anchorX = @move_bg_bar.cameraOffset.x
    console.log 'XXXXXX'
    console.log @move_anchorX
    @move_bar = @setupSprite('bluebar', screenFractionW,
      screenW * (0.5 - screenFractionW),
      screenH - @action_sprite.height,
      0.0, 0,
      0.01, 0.02,
      1.6)
    @move_max_width = @move_bar.width / @move_bar.scale.x
    @crop_move = new Phaser.Rectangle(0, 0, 
      @move_max_width, 
      @move_bar.height / @move_bar.scale.y)
    @move_bar.crop(@crop_move)
    @move_bar.updateCrop()
    # ==============================
    # SHOT BAR
    @shot_bg_bar = @setupSprite('redbar', screenFractionW,
      screenW * (0.5 - screenFractionW) + @move_bg_bar.width, 
      screenH - @action_sprite.height,
      0.0, 0,
      0.01, 0.02,
      0.8)
    @shot_bg_bar.alpha = 0.3
    @shot_bar = @setupSprite('redbar', screenFractionW,
      screenW * (0.5 - screenFractionW) + @move_bg_bar.width, 
      screenH - @action_sprite.height,
      0.0, 0,
      0.01, 0.02,
      0.8)
    @shot_max_width = @shot_bar.width / @shot_bar.scale.x
    @crop_shot = new Phaser.Rectangle(0, 0, 
      @shot_max_width, 
      @shot_bar.height / @shot_bar.scale.y)
    @shot_bar.crop(@crop_shot)
    @shot_bar.updateCrop()
    # ==============================
    # CHARGE BAR
    # For cropping we need to anchor the redbar at 0,0.  This makes setting its
    # X,Y a little trickier.  We set it to screenW / 2, then shift over by its
    # screenFractionW/2
    screenFractionW = 0.38
    @charge_bg_bar = @setupSprite('redbar', screenFractionW,
      screenW * (0.5 - screenFractionW/2), 
      @action_sprite.cameraOffset.y - @action_sprite.height/2.2,
      0.0, 0,
      0.01, 0.0)
    @charge_bg_bar.alpha = 0.3
    @charge_bar = @setupSprite('redbar', screenFractionW,
      screenW * (0.5 - screenFractionW/2), 
      @action_sprite.cameraOffset.y - @action_sprite.height/2.2,
      0, 0,
      0.01, 0.0)
    @charge_max_width = @charge_bar.width / @charge_bar.scale.x
    @crop_charge = new Phaser.Rectangle(0, 0, 
      1, 
      @charge_bar.height / @charge_bar.scale.y)
    @charge_bar.crop(@crop_charge)
    @charge_bar.updateCrop()
    # saves the last shot charge for player
    screenFractionW = 0.02
    @charge_save = @setupSprite('icon_shot_save', screenFractionW,
      @charge_bar.cameraOffset.x,
      @charge_bar.cameraOffset.y,
      0.5, 0,
      0.0, -0.015)

  # ============================================================================
  #                              WEAPON BUTTONS
  # ============================================================================
  @pickWeaponCallback: (btn) ->
    btn.on = true
    btn.setFrames(2, 2, 2)
    @sprites_wep[btn.id].alpha = 1
    btn.alpha = 1
    for otherbtn in @buttons_wep
      if otherbtn == btn
        continue
      otherbtn.on = false
      otherbtn.setFrames(1, 0, 2)
      @sprites_wep[otherbtn.id].alpha = 0.5
      otherbtn.alpha = 0.75

    # XXX need to send @shost.sessionid to associate with correct Player
    @shost.playerSetWeapon(btn.id)

  # XXX Only need this while single player, need to revert UI to match the
  # @active_player's weapon selection
  @refreshWeaponUI: (wep_num) ->
    @pickWeaponCallback(@buttons_wep[wep_num])

  @setupWeaponButtons: () ->

    screenW = @shost.game.width
    screenH = @shost.game.height

    screenFractionW = 0.07
    @button_wep1 = @setupButton(
      'buttonchoose', screenFractionW, 
      0, screenH,
      0, 1,
      0.01, -0.01,
      @pickWeaponCallback)
    @button_wep1.id = 0
    @buttons_wep.push(@button_wep1)

    sprite_wep1 = @setupSprite(
      'bullet', screenFractionW * 0.8,
      0, screenH,
      0, 1,
      0.01 + screenFractionW*0.1, 
      -0.01 - screenFractionW * 0.1)

    @sprites_wep.push(sprite_wep1)

    # activate weapon 1
    @pickWeaponCallback(@button_wep1)

    @button_wep2 = @setupButton(
      'buttonchoose', screenFractionW, 
      screenFractionW * screenW, screenH,
      0, 1,
      0.015, -0.01,
      @pickWeaponCallback)
    @button_wep2.id = 1
    @buttons_wep.push(@button_wep2)

    sprite_wep2 = @setupSprite(
      'missile1', screenFractionW * 0.8,
      screenFractionW * screenW, screenH,
      0, 1,
      0.015 + screenFractionW*0.1, 
      -0.01 - screenFractionW*0.1)

    @sprites_wep.push(sprite_wep2)

    @button_wep3 = @setupButton(
      'buttonchoose', screenFractionW, 
      2*screenFractionW * screenW, screenH,
      0, 1,
      0.02, -0.01,
      @pickWeaponCallback)
    @button_wep3.id = 2
    @buttons_wep.push(@button_wep3)

    sprite_wep3 = @setupSprite(
      'tbullet', screenFractionW * 0.8,
      2*screenFractionW * screenW, screenH,
      0, 1,
      0.02 + screenFractionW*0.1, 
      -0.01 - screenFractionW*0.1)

    @sprites_wep.push(sprite_wep3)

  # ============================================================================
  #                                TURN UI
  # ============================================================================
  @setupTurnUI: () ->

    screenW = @shost.game.width
    screenH = @shost.game.height

    screenFractionW = 0.02
    """
    @turn_text = new Phaser.BitmapText(@shost.game, 
      0, 
      0, 'bitfont', 'Player Turn', 20)
    @turn_text.fixedToCamera = true
    @turn_text.cameraOffset.set(
      screenFractionW * screenW,
      screenFractionW * screenH)
    @ui_group.add(@turn_text)
    """

    @turn_time_text = new Phaser.BitmapText(@shost.game,
      0,
      0,
      'rednum', '', 42)
    @turn_time_text.fixedToCamera = true
    @turn_time_text.cameraOffset.set(
      screenFractionW * 1.2 * screenW, 
      screenFractionW * 1.2 * screenH)
    @ui_group.add(@turn_time_text)

  @bringToTop: () ->
    @shost.game.world.bringToTop(@ui_group)

  @updateMoveBar: (fraction) ->
    newWidth = @move_max_width * fraction
    newWidth = GameMath.clamp(newWidth, 1, @move_max_width)
    diff = @move_max_width - newWidth
    @move_bar.cameraOffset.x = @move_anchorX + diff * @move_bg_bar.scale.x
    @crop_move.x = diff
    @crop_move.width = newWidth
    @move_bar.updateCrop()

  @updateShotBar: (fraction) ->
    newWidth = @shot_max_width * fraction
    newWidth = GameMath.clamp(newWidth, 1, @shot_max_width)
    @crop_shot.width = newWidth
    @shot_bar.updateCrop()

  @updateChargeBar: (fraction) ->
    newWidth = @charge_max_width * fraction
    newWidth = GameMath.clamp(newWidth, 1, @charge_max_width)
    @crop_charge.width = newWidth
    @charge_bar.updateCrop()

  @refreshChargeSave: (fraction) ->
    @charge_save.cameraOffset.x = @charge_bar.cameraOffset.x + @charge_max_width * @charge_bar.scale.x * fraction

  @updateTurnText: (text) ->
    #@turn_text.setText(text)
    null

  @updateTurnTime: (tremaining) ->
    # if turn time is not below show time, hide the time display
    if tremaining > GameConstants.turnShowTime
      @turn_time_text.visible = false
    # if turn time is in warn time, show time in red
    else if tremaining > 0
      @turn_time_text.visible = true
      @turn_time_text.setText(tremaining.toString())
    # if turn time is negative or 0, hide it
    else
      @turn_time_text.visible = false

