module main

fn test_platformer_initialization() {
	mut game := new_platformer_game()
	assert game.current_level == 1
	assert game.player.health == 3
	assert game.player.lives == 3
	assert game.map.cols > 0
	assert game.map.rows > 0
	assert game.player.x > 0
	assert game.player.y > 0
}

fn test_platformer_gravity_and_jump() {
	mut game := new_platformer_game()

	// Initial update in air
	game.update(0.016, false, false, false, false, false, false, false)
	assert game.player.vy > 0 // Falling under gravity

	// Force player onto ground
	game.player.y = (game.map.rows - 4) * tile_size
	game.player.vy = 0
	game.player.grounded = true

	// Jump input
	game.update(0.016, false, false, true, false, false, false, false)
	assert game.player.vy < 0 // Moving upward after jump
	assert game.sound_event_jump == true
}

fn test_platformer_dash_mechanic() {
	mut game := new_platformer_game()
	game.player.dash_cooldown = 0

	// Trigger dash right
	game.update(0.016, false, true, false, false, false, true, false)
	assert game.player.is_dashing == true
	assert game.player.vx >= dash_speed * 0.9
	assert game.sound_event_dash == true
}

fn test_platformer_coin_collection() {
	mut game := new_platformer_game()
	initial_coins := game.player.coins
	initial_score := game.player.score

	// Place coin right on player
	tx := int(game.player.x / tile_size)
	ty := int(game.player.y / tile_size)
	game.map.tiles[ty][tx] = .coin

	game.update(0.016, false, false, false, false, false, false, false)
	assert game.player.coins == initial_coins + 1
	assert game.player.score > initial_score
	assert game.sound_event_coin == true
}

fn test_platformer_hazard_and_respawn() {
	mut game := new_platformer_game()
	initial_health := game.player.health

	game.player.invuln_timer = 0
	game.hurt_player()

	assert game.player.health == initial_health - 1
	assert game.player.invuln_timer > 0
	assert game.sound_event_hit == true
}

fn test_platformer_level_progression() {
	mut game := new_platformer_game()
	game.load_level(2)
	assert game.current_level == 2
	assert game.map.cols == 35

	game.load_level(3)
	assert game.current_level == 3
	assert game.map.cols == 40
}
