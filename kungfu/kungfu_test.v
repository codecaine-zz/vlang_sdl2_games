module main

fn test_game_init_and_reset() {
	mut game := new_kung_fu_game()
	assert game.state == .title
	assert game.floor == 1
	assert game.player.lives == 3

	game.start_game()
	assert game.state == .playing
	assert game.player.health == 16
	assert game.player.x == 100.0
	assert game.player.facing_right == true
}

fn test_floor_progression() {
	mut game := new_kung_fu_game()
	game.start_game()

	// Floor 1 -> Left to Right
	assert game.floor == 1
	assert game.player.facing_right == true

	// Floor 2 -> Right to Left
	game.next_floor()
	assert game.floor == 2
	assert game.player.x == 2300.0
	assert game.player.facing_right == false

	// Floor 3
	game.next_floor()
	assert game.floor == 3
	assert game.player.x == 100.0
}

fn test_player_attacks_and_hits() {
	mut game := new_kung_fu_game()
	game.start_game()
	game.enemies.clear()

	// Spawn a knife thrower right in front of player (Player at X=100..128, Hitbox at X=128..156, Y=410..430)
	game.enemies << Enemy{
		id: 1
		enemy_type: .knife_thrower
		x: 130.0
		y: 400.0
		health: 1
		active: true
	}

	assert game.enemies.len == 1
	game.trigger_attack(.high_punch)
	assert game.player.attack == .high_punch
	assert game.player.score >= 200
	game.update(0.01)
	assert game.enemies.len == 0 // Defeated and filtered
}

fn test_deflect_projectile() {
	mut game := new_kung_fu_game()
	game.start_game()
	game.enemies.clear()

	// Incoming knife in strike zone
	game.projectiles << Projectile{
		x: 135.0
		y: 418.0
		vx: -200.0
		active: true
	}

	game.trigger_attack(.high_kick)
	assert game.player.score == 500
	game.update(0.01)
	assert game.projectiles.len == 0 // Destroyed/deflected
}

fn test_gripper_latch_and_shakeoff() {
	mut game := new_kung_fu_game()
	game.start_game()
	game.enemies.clear()

	// Latched gripper
	game.enemies << Enemy{
		id: 1
		enemy_type: .gripper
		x: 100.0
		y: 400.0
		is_grabbing: true
		active: true
	}
	game.player.grabbed_count = 1

	assert game.player.grabbed_count == 1
	game.shake_off_grippers()
	assert game.player.grabbed_count == 0
	game.update(0.01)
	assert game.enemies.len == 0
}

fn test_sound_toggle() {
	mut sm := new_sound_manager()
	initial := sm.sound_enabled
	toggled := sm.toggle_sound()
	assert toggled != initial
}
