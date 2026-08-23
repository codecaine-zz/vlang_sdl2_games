module main

fn test_player_aiming_and_shooting() {
	mut game := new_contra_game()
	game.start_game(1, false)

	assert game.players.len > 0
	p := game.players[0]
	assert p.lives >= 3

	// Test Spread Gun bullet generation
	bullets := create_player_bullets(100.0, 100.0, 1.0, 0.0, .spread_gun, false, 1)
	assert bullets.len == 5
	for b in bullets {
		assert b.is_player
		assert b.damage >= 1
	}

	// Test Laser bullet generation
	laser_bullets := create_player_bullets(100.0, 100.0, 1.0, 0.0, .laser, false, 1)
	assert laser_bullets.len == 1
	assert laser_bullets[0].piercing
	assert laser_bullets[0].damage == 3
}

fn test_konami_code() {
	mut game := new_contra_game()
	assert !game.konami_activated

	// Input Konami Code: Up, Up, Down, Down, Left, Right, Left, Right, B, A
	code := [1, 1, 2, 2, 3, 4, 3, 4, 5, 6]
	for k in code {
		game.push_konami_key(k)
	}
	assert game.konami_activated

	game.start_game(1, false)
	assert game.players[0].lives == 30
}

fn test_stage_loading() {
	for s := 1; s <= 4; s++ {
		sd := get_stage_by_number(s)
		assert sd.def.stage_num == s
		assert sd.platforms.len > 0
		assert sd.def.length > 0
	}
}

fn test_pop_texts_and_shake() {
	mut game := new_contra_game()
	game.start_game(1, false)

	game.add_pop_text('+500 SPREAD GUN!', 200, 200, 255, 220, 40)
	assert game.pop_texts.len == 1

	game.trigger_shake(0.5)
	assert game.shake_trauma > 0.4
}

fn test_bridge_collision() {
	mut game := new_contra_game()
	game.start_game(1, false)
	game.state = .playing

	// Position player just above bridge segment with downward velocity
	game.players[0].x = 800.0
	game.players[0].y = 398.0
	game.players[0].vy = 200.0

	game.update(0.016)

	p := game.players[0]
	// Player should land on top of bridge at y = 400.0
	assert p.on_ground
	assert p.y == 400.0
}
