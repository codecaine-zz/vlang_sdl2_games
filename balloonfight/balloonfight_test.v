module main

fn test_new_game_engine() {
	ge := new_game_engine()
	assert ge.state == .title
	assert ge.mode == .mode_a_1p
	assert ge.high_score == 25000
	assert ge.world_w == 800.0
	assert ge.world_h == 600.0
}

fn test_flap_physics() {
	mut m := MotionState{
		x:           200
		y:           300
		vx:          0
		vy:          0
		is_grounded: true
	}
	apply_flap(mut m, 180.0)
	assert m.vy == -180.0
	assert m.is_grounded == false
}

fn test_wraparound_physics() {
	mut m := MotionState{
		x:           -25.0
		y:           300
		vx:          -50.0
		vy:          0
		is_grounded: false
	}
	update_motion(mut m, 0.016, 800.0)
	assert m.x > 700.0
}

fn test_stage_setup() {
	mut ge := new_game_engine()
	ge.start_game(.mode_a_1p)
	assert ge.state == .playing
	assert ge.players.len == 1
	assert ge.enemies.len > 0
	assert ge.platforms.len > 0
}

fn test_balloon_collisions() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Position player directly above enemy (p_feet <= e_head + 12)
	ge.players[0].motion.x = 200.0
	ge.players[0].motion.y = 90.0
	ge.players[0].motion.vy = 50.0

	ge.enemies[0].motion.x = 200.0
	ge.enemies[0].motion.y = 120.0
	ge.enemies[0].motion.vy = 0.0
	ge.enemies[0].balloons = 2
	ge.enemies[0].state = .flying

	ge.check_balloon_collisions(&sm)

	assert ge.enemies[0].balloons == 1
}

fn test_giant_fish_trigger() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Player hovers low over water
	ge.players[0].motion.x = 300.0
	ge.players[0].motion.y = 480.0
	ge.fish.cooldown = 3.5

	ge.update_giant_fish(0.016, &sm)

	assert ge.fish.active == true
	assert ge.fish.x == 300.0
}

fn test_ledge_fall_gravity() {
	platforms := [
		Platform{x: 100.0, y: 300.0, w: 100.0, h: 20.0},
	]
	// Standing on platform
	mut m := MotionState{
		x:           150.0
		y:           300.0 - 18.0 // Center of character (h=36)
		vx:          0
		vy:          0
		is_grounded: true
	}
	// Verify supported
	assert update_platforms_collision(mut m, 28.0, 36.0, platforms) == true
	assert m.is_grounded == true

	// Walk off the right edge (x past 200 + char_w/2)
	m.x = 220.0
	assert update_platforms_collision(mut m, 28.0, 36.0, platforms) == false
	assert m.is_grounded == false

	// Update motion - gravity MUST accelerate downward
	update_motion(mut m, 0.05, 800.0)
	assert m.vy > 0.0
	assert m.y > (300.0 - 18.0)
}

fn test_defeat_pumping_enemy_by_running_into_them() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Both player and enemy on same platform level
	ge.players[0].motion.x = 200.0
	ge.players[0].motion.y = 282.0
	ge.enemies[0].motion.x = 210.0
	ge.enemies[0].motion.y = 282.0
	ge.enemies[0].state = .pumping
	ge.enemies[0].active = true

	ge.check_balloon_collisions(&sm)

	assert ge.enemies[0].active == false
	assert ge.score > 0
}

fn test_player_zero_balloons_instant_death() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	initial_lives := ge.players[0].lives
	ge.players[0].balloons = 1
	ge.players[0].invincibility = 0
	ge.players[0].motion.x = 200.0
	ge.players[0].motion.y = 200.0

	// Position enemy directly above player to pop last balloon
	ge.enemies[0].motion.x = 200.0
	ge.enemies[0].motion.y = 180.0
	ge.enemies[0].state = .flying
	ge.enemies[0].active = true

	ge.check_balloon_collisions(&sm)

	// Player should immediately lose 1 life and respawn with 2 balloons
	assert ge.players[0].lives == initial_lives - 1
	assert ge.players[0].balloons == 2
	assert ge.players[0].state == .flying
}
