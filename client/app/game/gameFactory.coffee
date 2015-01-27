window.createGame = (scope, players, mapId, ele, injector) ->
  # height  = parseInt ele.css('height'), 10
  # width   = parseInt ele.css('width'), 10
  game = new Phaser.Game(1024, 640, Phaser.CANVAS, "gameCanvas")
  # Cleanup
  scope.$on '$destroy', ->
    console.log "game destroyed."
    # socket.emit 'playerLeftMap', {
    #   playerId: g.sid
    #   mapId: g.mapId
    # }
    game.destroy()

  # XXX: right now global window is polluted with game states,
  #      will change later
  game.state.add 'Boot', new BootState, false
  game.state.add 'Preloader', new PreloaderState, false
  game.state.add 'MainMenu', new MainMenuState, false
  game.state.add 'Play', new PlayState, false
  game.state.start 'Boot', true, false, null