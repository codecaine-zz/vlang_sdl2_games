module main

fn test_game_init_and_reset() {
	mut game := new_legend_of_kage_game()
	assert game.state == .title
	assert game.player.lives == 3

	game.start_game()
	assert game.state == .playing
	assert game.stage == .forest
	assert game.branches.len > 0
}

fn test_player_jump_and_gravity() {
	mut game := new_legend_of_kage_game()
	game.start_game()
	game.player.y = 480.0
	game.player.is_grounded = true
	game.key_jump = true

	game.update(0.016)
	assert game.player.vy < 0.0 // moving upwards into the air
}

fn test_sword_parry_projectile() {
	mut game := new_legend_of_kage_game()
	game.start_game()
	game.player.x = 200.0
	game.player.y = 480.0
	game.player.facing_right = true

	// Incoming enemy shuriken
	game.projectiles.clear()
	game.projectiles << Projectile{
		x: 220.0
		y: 490.0
		vx: -200.0
		vy: 0.0
		is_player: false
		active: true
	}

	game.player_slash()
	assert game.projectiles[0].active == false
}

fn test_ninjutsu_scroll_pickup() {
	mut game := new_legend_of_kage_game()
	game.start_game()
	game.player.x = 300.0
	game.player.y = 480.0

	game.scrolls.clear()
	game.scrolls << MagicScroll{
		x: 304.0
		y: 490.0
		scroll_type: .golden_speed
		active: true
	}

	game.update(0.016)
	assert game.player.active_jutsu == .golden_speed
	assert game.player.jutsu_timer > 0.0
	assert game.scrolls.len == 0
}

fn test_sound_toggle() {
	mut sm := new_sound_manager()
	initial := sm.sound_enabled
	toggled := sm.toggle_sound()
	assert toggled != initial
}
