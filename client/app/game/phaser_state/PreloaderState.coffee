class @PreloaderState extends Phaser.State
  
	constructor: -> 
    super
    @assetPrefix = "assets/images/"
    
	preload: ->
    @createPreloader()
    @loadAssets()

	createPreloader: =>
    @preloader = @game.add.sprite(200, 250, "preloader")
    @load.setPreloadSprite(@preloader)

	loadAssets: =>
    console.log(@getAssetPath)

    # font
    @game.load.bitmapFont("bitfont", @getAssetPath("font.png"), @getAssetPath("font.fnt"))
    @game.load.bitmapFont("rednum", @getAssetPath("rednumbers.png"), @getAssetPath("rednumbers.fnt"))

    @game.load.image("logo", @getAssetPath("phaser.png"))
    @game.load.image("player", @getAssetPath("player.png"))
    @game.load.image("reticule", @getAssetPath("reticule.png"))

    # explosives and stuff
    @game.load.image("bullet", @getAssetPath("bullet.png"))
    @game.load.image("tbullet", @getAssetPath("teleport_bullet.png"))
    @game.load.image("missile1", @getAssetPath("missile1.png"))
    @game.load.image("explosion", @getAssetPath("explosion_flat.png"))
    @game.load.image("spark", @getAssetPath("spark.png"))
    @game.load.image("spark_blue", @getAssetPath("spark_blue.png"))
    @game.load.image("glow", @getAssetPath("glow.png"))
    @game.load.image("ring", @getAssetPath("ring.png"))
    @game.load.image("flare", @getAssetPath("flare.png"))
    @game.load.image("pebble", @getAssetPath("pebble.png"))
    @game.load.image("smoke", @getAssetPath("smoke_flat.png"))

    #@game.load.image("ground", @getAssetPath("ground.png"))
    #@game.load.image("world_bridge", @getAssetPath("world_bridge.png"))
    @game.load.image("world_divide", @getAssetPath("world_divide.png"))
    @game.load.image("background", @getAssetPath("background.png"))
    @game.load.image("health", @getAssetPath("health.png"))
    @game.load.image("healthbar", @getAssetPath("healthbar.png"))

    # ui
    @game.load.image("actionui", @getAssetPath("actionui.png"))
    @game.load.image("icon_move", @getAssetPath("icon_move.png"))
    @game.load.image("icon_shot", @getAssetPath("icon_shot.png"))
    @game.load.image("bluebar", @getAssetPath("bluebar.png"))
    @game.load.image("redbar", @getAssetPath("redbar.png"))
    @game.load.image("icon_shot_save", @getAssetPath("icon_shot_save.png"))
    @game.load.spritesheet("buttonchoose", 
        @getAssetPath("buttonchoose_sheet.png"),
        119, 119)

    @game.time.advancedTiming = true

	create: ->
    @startMainMenu()

  getAssetPath: (asset) =>
    return (@assetPrefix + asset)

	startMainMenu: ->
    @game.state.start "MainMenu", true, false