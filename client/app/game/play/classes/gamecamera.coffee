class @GameCamera

  constructor: (@shost) ->
    null

  initialize: (@zoom) ->
    # the sprite being followed, if any
    @following = null
    # if we force camera to detach from following, mark it for restoration
    @restoreFollowing = null
    # Non-UI display objects that should not be affected by zoom and pan 
    # should be added to this group
    @noZoomGroup = @shost.game.add.group()

    # For e.g., effects or player manually moving, forcefully detach camera 
    # from any following action and mark camera state as forcefully
    # detached, so we can later restore if necessary
    @forceDetach = false
    # When the player is moving the camera, we don't do any of the automatic
    # moving of the camera until the player releases camera
    @playerMove = false

    # effects
    @joltArray = []    # store positions to jolt camera violently for a bit
    @easing = false    # glides camera to targeted destination
    @easeFactor = 0.2  # how fast camera eases
    @easeX = 0         # target X to ease to
    @easeY = 0         # target Y to ease to
    @lastXY = [-1, -1] # keeps track of camera's last update X,Y to catch it if
                       # it's trying to move but gets stuck in one place, such
                       # as if it's trying to move past world bounds
    @lastXYSameCount = 0

  # XXX Camera zoom is broken in Phaser and with any scale that isn't 1, 
  # produces weird scaled movement, so zooming is currently disallowed
  setZoom: (amt) ->
    @zoom = amt
    @updateZoom()

  zoomIn: (amt) ->
    @addZoom(amt)

  zoomOut: (amt) ->
    @addZoom(-amt)

  addZoom: (amt) ->
    @zoom += amt
    @updateZoom()

  updateZoom: () ->
    izoom = 1.0 / @zoom
    @shost.game.world.scale.set(@zoom, @zoom)
    @noZoomGroup.scale.set(izoom, izoom)

  addNoZoomSprite: (sp) ->
    @noZoomGroup.add(sp)

  addFixedSprite: (sp) ->
    sp.fixedToCamera = true
    @noZoomGroup.add(sp)

  clearEffects: () ->
    @forceDetach = false
    @joltArray = []
    @easing = false
    @unfollow()
    @restoreFollowing = null

  playerMoveCamera:(x, y) ->
    if !@playerMove
      @playerMove = true
      @clearEffects()
    @shost.game.camera.x -= x * GameConstants.cameraDragRate
    @shost.game.camera.y -= y * GameConstants.cameraDragRate

  playerReleaseCamera:() ->
    @playerMove = false

  easeTo: (x, y) ->
    if @playerMove
      return
    @easeX = x
    @easeY = y
    @easing = true
    @forceDetach = true
    @restoreFollowing = @following
    @unfollow()

  # This is simply a screen space effect so don't need dt in update
  jolt: (x, y) ->
    if @playerMove
      return
    @forceDetach = true
    @restoreFollowing = @following
    @unfollow()
    
    curX = @shost.game.camera.x
    curY = @shost.game.camera.y

    @joltArray = []
    joltPx = GameConstants.cameraJoltPx
    joltFactor = 1.0
    numJolts = 15
    dFactor = joltFactor/numJolts
    for i in [0...numJolts]
      curFactor = joltFactor - dFactor*i
      @joltArray.push([
        (curX + Math.random()*joltPx - joltPx/2)*joltFactor, 
        (curY + Math.random()*joltPx - joltPx/2)*joltFactor])

  center: (asprite) ->
    if @playerMove
      return
    @shost.game.camera.focusOn(asprite)

  follow: (asprite) ->
    if @playerMove
      return
    #console.log 'following'
    #console.log asprite
    @following = asprite
    @restoreFollowing = null
    @shost.game.camera.follow(asprite)
    @setDeadzone(GameConstants.cameraDeadzoneY)

  restoreFollow: () ->
    if @playerMove
      return
    if @restoreFollowing == null
      return
    #console.log 'restoring'
    #console.log @restoreFollowing
    @follow(@restoreFollowing)
    @restoreFollowing = null
    @forceDetach = false

  setDeadzone: (height) ->
    @shost.game.camera.deadzone = new Phaser.Rectangle(
      @shost.game.stage.bounds.width / 2,
      @shost.game.stage.bounds.height / 2 - height/2,
      1,
      height
      )

  unfollow:() ->
    #curX = @shost.game.camera.x
    #curY = @shost.game.camera.y
    @following = null
    @shost.game.camera.follow(null)
    #@shost.game.camera.x = curX
    #@shost.game.camera.y = curY

  unfollowIfFollowing: (asprite) ->
    if @following == asprite
      #console.log 'unfollowing' + asprite
      @unfollow()

  update: (dt) ->
    if @playerMove
      return

    if !@forceDetach
      return

    curX = @shost.game.camera.x
    curY = @shost.game.camera.y

    # ========================
    # Easing
    if @easing
      # easing takes precedence over jolt effect, so clear jolting
      @joltArray = []

      # Do easing
      tX = @easeX - curX
      tY = @easeY - curY
      # if close enough to target position @easeX/Y, just snap to it
      closeEnough = 4
      if Math.abs(tX) < closeEnough && Math.abs(tY) < closeEnough
        @shost.game.camera.x = @easeX
        @shost.game.camera.y = @easeY
        @easing = false
      else
        @shost.game.camera.x += Math.ceil(tX * @easeFactor)
        @shost.game.camera.y += Math.ceil(tY * @easeFactor)

      # If position has not changed since last update for a while, that means 
      # we're stuck and so give up
      if curX == @lastXY[0] && curY == @lastXY[1]
        @lastXYSameCount += 1
      if @lastXYSameCount > 10
        if GameConstants.debug
          console.log 'easing is stuck, giving up...'
        @easing = false
        @lastXYSameCount = 0
    # ========================
    # Jolt
    else if @joltArray.length > 0
      jolt = @joltArray.pop()
      @shost.game.camera.x = jolt[0]
      @shost.game.camera.y = jolt[1]
    else
      @restoreFollow()

    @lastXY = [curX, curY]

  kill: () ->
    @noZoomGroup.removeAll()



