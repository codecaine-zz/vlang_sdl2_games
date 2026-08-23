module main

fn test_game_init_and_reset() {
	mut game := new_yie_ar_kung_fu_game()
	assert game.state == .title
	assert game.stage_idx == 0

	game.start_game()
	assert game.state == .fighting
	assert game.opponent_type == .wang
	assert game.player.hp == 100
	assert game.opponent.hp == 100
}

fn test_player_attacks() {
	mut game := new_yie_ar_kung_fu_game()
	game.start_game()

	// High punch
	game.key_up = true
	game.perform_player_attack(false)
	assert game.player.move == .high_punch

	// Reset
	game.player.move = .idle
	game.player.attack_cooldown = 0.0

	// Flying kick
	game.player.is_grounded = false
	game.player.is_jumping = true
	game.key_right = true
	game.perform_player_attack(true)
	assert game.player.move == .flying_kick
}

fn test_hit_opponent() {
	mut game := new_yie_ar_kung_fu_game()
	game.start_game()

	game.player.x = 350.0
	game.opponent.x = 390.0
	game.player.move = .high_kick

	game.check_combat_hits()
	assert game.opponent.hp < 100
	assert game.score > 0
}

fn test_projectile_deflection() {
	mut game := new_yie_ar_kung_fu_game()
	game.start_game()

	game.player.x = 300.0
	game.player.move = .high_punch

	game.projectiles << Projectile{
		x: 320.0
		y: 395.0
		vx: -200.0
		vy: 0.0
		is_fire: false
		active: true
	}

	game.update(0.016)
	assert game.projectiles.len == 0 // Deflected & cleaned up
}

fn test_sound_toggle() {
	mut sm := new_sound_manager()
	initial := sm.sound_enabled
	toggled := sm.toggle_sound()
	assert toggled != initial
}
