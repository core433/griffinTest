# Entity object
#
# Represents the physical (not graphical) object in the scene.
# Contains one p2.js physics body for physics sim, and a box size
# which acts as its collision body
#
class @Entity

  constructor: (@shost) ->
    @x = 0
    @y = 0
    @width = 0
    @height = 0
    # by default (x,y) is the center of the Entity
    # offX and offY will shift the collision box relative to the
    # center
    @offX = 0
    @offY = 0
    @p2body = null

    @fx = 0
    @fy = 0

    @bmp = null
    @previz = null

  initialize: (@x, @y, @width, @height, @offX, @offY) ->
    @p2body = new p2.Body({
          mass: 10,
          position:[@x,@y],
          fixedRotation: true,
        });
    bodyMaterial = new p2.Material()
    bodyShape = new p2.Rectangle(1,1)
    bodyShape.material = bodyMaterial
    @p2body.addShape(bodyShape)

  setForce: (@fx, @fy) ->
    null

  initPreviz: (game) ->
    # Make the test bmp for drawing
    @bmp = game.make.bitmapData(@width, @height)
    @previz = new Phaser.Sprite(game, 0, 0, @bmp)
    @shost.playgroup.add(@previz)
    @bmp.ctx.fillStyle = 'rgba(255,0,0,0.5)'
    @bmp.ctx.fillRect(0, 0, @width, @height)

  minX: ->
    return @x + @offX - Math.floor(@width/2)
  maxX: ->
    return @x + @offX + Math.floor(@width/2)
  minY: ->
    return @y + @offY - Math.floor(@height/2)
  maxY: ->
    return @y + @offY + Math.floor(@height/2)

  setX: (newX) ->
    @p2body.position[0] = newX
    @p2body.velocity[0] = 0
    @x = newX

  getX: ->
    return @x

  setY: (newY) ->
    @p2body.position[1] = newY
    @p2body.velocity[0] = 0
    @y = newY

  getY: ->
    return @y

  update: ->
    oldx = @x
    oldy = @y
    @x = @p2body.position[0]
    @y = @p2body.position[1]

    @p2body.force[0] = @fx
    @p2body.force[1] = @fy

    if @previz != null
      @previz.x = @x + @offX - @width/2
      @previz.y = @y + @offY - @height/2

    return oldx !=@x || oldy != @y

  kill: ->
    if @previz
      @previz.destroy(true)
      @previz = null
    @bmp = null
    @p2body = null

  collidesWithEntity: (entity) ->
    # Don't need to check every point of the rectangles, just need to check
    # if the bottoms are outside of each others' reach
    topLeft1 = [@minX(), @minY()]
    topLeft2 = [entity.minX(), entity.minY()]
    botRight1 = [@maxX(), @maxY()]
    botRight2 = [entity.maxX(), entity.maxY()]

    if (topLeft1[0] > botRight2[0] || topLeft2[0] > botRight1[0])
      return false
    if (topLeft1[1] > botRight2[1] || topLeft2[1] > botRight1[1])
      return false

    return true

  # Most objects in the game will adhere to an Entity class, but the world is
  # a special case since it's a bitmap data, so we need special considerations
  # when colliding against the world.
  collidesWithWorld: (world) ->

    # From the bottom left pixel of the entity to the top right pixel,
    # spaced by world.tileSize apart, get the world tile value and see if 
    # is ground

    minTileX = GameMath.clamp(world.xTileForWorld(@minX()), 0, world.width-1)
    maxTileX = GameMath.clamp(world.xTileForWorld(@maxX()), 0, world.width-1)
    minTileY = GameMath.clamp(world.yTileForWorld(@minY()), 0, world.height-1)
    maxTileY = GameMath.clamp(world.yTileForWorld(@maxY()), 0, world.height-1)
    for i in [minTileX...maxTileX]
      for j in [minTileY...maxTileY]
        rgba_str = world.data[i][j]
        if world.isGround(rgba_str)
          return true
    return false








