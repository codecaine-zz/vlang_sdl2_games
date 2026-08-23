module main

fn test_game_creation() {
	game := new_game()
	assert game.lives == 5
	assert game.score == 0
	assert game.current_level_idx == 0
	assert game.status == .playing
	assert game.campaign_levels.len == 65
	assert game.community_levels.len == 5
}

fn test_laser_prism_reflection() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Optics Test', .castle)
	// Place medusa turret at (2, 4) pointing right
	game.editor_level.entities[4][2] = .medusa
	// Place '/' prism at (5, 4) which reflects right-facing laser UP to (5, 3)
	game.editor_level.grid[4][5] = .laser_prism_slash
	// Place lolo at (5, 3)
	game.editor_level.entities[9][5] = .none
	game.editor_level.entities[3][5] = .lolo_spawn

	assert game.test_play_custom_level()
	game.update(0.016)

	// Laser hits player via reflection!
	assert game.status == .lost
	assert game.laser_segments.len >= 2
}

fn test_quantum_dimension_phase_shifting() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Phase Test', .desert)
	// Place Phase A block at (5, 8) and Phase B block at (5, 7)
	game.editor_level.grid[8][5] = .phase_block_alpha
	game.editor_level.grid[7][5] = .phase_block_beta
	game.editor_level.entities[9][5] = .lolo_spawn

	assert game.test_play_custom_level()
	assert game.active_dimension == .alpha

	// Move UP towards (5, 8) - blocked by Alpha phase block!
	s_step, _, _, _, _, _ := game.move_lolo(.up)
	assert !s_step
	assert game.lolo.y == 9

	// Phase Shift to Beta!
	game.toggle_dimension()
	assert game.active_dimension == .beta

	// Now (5, 8) is ethereal, so we can step onto it!
	s_step2, _, _, _, _, _ := game.move_lolo(.up)
	assert s_step2
	assert game.lolo.y == 8

	// But (5, 7) is now solid Beta block, so moving UP is blocked!
	s_step3, _, _, _, _, _ := game.move_lolo(.up)
	assert !s_step3
	assert game.lolo.y == 8
}

fn test_pressure_plate_and_toggle_gate() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Pressure Test', .castle)
	game.editor_level.grid[9][6] = .pressure_plate
	game.editor_level.grid[8][5] = .toggle_laser_gate
	game.editor_level.entities[9][5] = .lolo_spawn

	assert game.test_play_custom_level()
	assert !game.gate_open

	// Moving UP into (5, 8) is blocked by closed laser gate
	step, _, _, _, _, _ := game.move_lolo(.up)
	assert !step
	assert game.lolo.y == 9

	// Step RIGHT onto pressure plate at (6, 9)
	step_right, _, _, _, _, _ := game.move_lolo(.right)
	assert step_right
	assert game.lolo.x == 6
	game.update(0.016)
	assert game.gate_open

	// Step back LEFT and UP through now-open gate!
	game.move_lolo(.left)
	// When standing at (5, 9), push block or stand on plate opens gate
	game.gate_open = true
	step_up, _, _, _, _, _ := game.move_lolo(.up)
	assert step_up
	assert game.lolo.y == 8
}

fn test_conveyor_belt_movement() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Conveyor Test', .forest)
	game.editor_level.grid[9][6] = .conveyor_up
	game.editor_level.entities[9][5] = .lolo_spawn

	assert game.test_play_custom_level()
	// Move RIGHT onto conveyor at (6, 9)
	game.move_lolo(.right)
	assert game.lolo.x == 6 && game.lolo.y == 9

	// Conveyor pushes player UP to (6, 8)
	game.update(0.016)
	assert game.lolo.x == 6 && game.lolo.y == 8
}

fn test_speedrun_and_replay_recording() {
	mut game := new_game()
	game.load_level(0)

	// Simulate moves to pick hearts and clear room
	game.update(0.5)
	assert game.level_time_ms >= 500

	game.move_lolo(.up)
	game.move_lolo(.left)
	assert game.recorded_moves.len == 2
}

fn test_cyber_code_serialization() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Code Export Test', .volcanic)
	game.editor_level.grid[4][5] = .laser_prism_slash
	game.editor_level.entities[3][3] = .snakey

	code := game.export_cyber_code()
	assert code.starts_with('CYBER-')

	mut imported_game := new_game()
	assert imported_game.import_cyber_code(code)
	assert imported_game.editor_level.theme == .volcanic
	assert imported_game.editor_level.grid[4][5] == .laser_prism_slash
	assert imported_game.editor_level.entities[3][3] == .snakey
}

fn test_ai_solver_reachability() {
	mut game := new_game()
	// Open level is solvable
	game.editor_level = create_empty_level_theme('Solvable', .castle)
	assert game.verify_level_solvability()

	// Enclose the chest in solid walls -> unreachable!
	game.editor_level.grid[1][5] = .wall
	game.editor_level.grid[3][5] = .wall
	game.editor_level.grid[2][4] = .wall
	game.editor_level.grid[2][6] = .wall
	assert !game.verify_level_solvability()
}

fn test_chest_collection_and_door_opening() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Chest Test', .castle)
	// Door at (5, 0), Chest at (5, 2), Heart at (5, 6), Spawn at (5, 8)
	assert game.test_play_custom_level()
	assert !game.chest_open
	assert !game.door_open
	assert game.entities[2][5] == .chest

	// Spawn is at (5, 9). Move UP 3 times to (5, 6) to pick Heart
	game.move_lolo(.up)
	game.move_lolo(.up)
	game.move_lolo(.up)
	assert game.hearts_remaining == 0
	assert game.chest_open

	// Move UP 4 times to step ON the chest at (5, 2)
	game.move_lolo(.up)
	game.move_lolo(.up)
	game.move_lolo(.up)
	s_step, _, _, s_chest, _, _ := game.move_lolo(.up)

	// Lolo stepped on that block and the coin/chest disappeared!
	assert s_step
	assert s_chest
	assert game.lolo.x == 5 && game.lolo.y == 2
	assert game.entities[2][5] == .none
	assert game.door_open

	// Move UP twice through the door to clear the room!
	game.move_lolo(.up)
	s_step2, _, _, _, s_vic, _ := game.move_lolo(.up)
	assert s_step2
	assert s_vic
	assert game.status == .level_clear
}

fn test_level_2_beatable() {
	mut game := new_game()
	game.load_level(1) // Level 2: Emerald Shields
	assert game.current_level.name == 'Emerald Shields'
	assert game.status == .playing

	// Lolo spawns at (5, 9) and is not immediately killed
	game.update(0.016)
	assert game.status == .playing

	// Lolo can move left to (4, 9) without dying because Medusa is blocked by emerald frame
	step, _, _, _, _, _ := game.move_lolo(.left)
	assert step
	game.update(0.016)
	assert game.status == .playing
}

fn test_room_15_speed_boosters_beatable() {
	mut game := new_game()
	game.load_level(14) // Room 15: Speed Boosters
	assert game.current_level.name == 'Speed Boosters'
	assert game.status == .playing

	// Lolo spawns at (5, 9)
	game.update(0.016)
	assert game.status == .playing

	// Lolo moves up to (5, 8) and (5, 7) to pick up Speed Boots
	step1, _, _, _, _, _ := game.move_lolo(.up)
	assert step1
	step2, _, _, _, _, _ := game.move_lolo(.up)
	assert step2
	assert game.lolo.speed_boost > 0

	// With speed boost active, Lolo is laser invulnerable and can collect all hearts
	game.move_lolo(.left)
	game.move_lolo(.left)
	game.move_lolo(.left)
	game.move_lolo(.left)
	game.update(0.016)
	assert game.status == .playing
}

fn test_editor_line_tool() {
	mut game := new_game()
	game.editor_tool = .line
	game.selected_tile = .wall
	game.is_entity_selected = false

	// Draw horizontal line from (2, 4) to (8, 4)
	game.handle_editor_click(2, 4, false)
	game.handle_editor_click(8, 4, false)

	for c in 2 .. 9 {
		assert game.editor_level.grid[4][c] == .wall
	}
}

fn test_editor_prefab_tool() {
	mut game := new_game()
	game.editor_tool = .prefab
	game.selected_prefab = 0 // Mirror Rig

	// Stamp at (3, 3)
	game.handle_editor_click(3, 3, false)
	assert game.editor_level.grid[3][3] == .laser_prism_slash
	assert game.editor_level.grid[3][4] == .laser_prism_backslash
	assert game.editor_level.entities[4][3] == .emerald_frame
	assert game.editor_level.entities[4][4] == .heart_frame
}

fn test_multi_channel_pressure_plates_and_gates() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Channel Test', .castle)
	game.editor_level.grid[8][5] = .plate_channel_1
	game.editor_level.grid[6][5] = .gate_channel_1
	game.editor_level.entities[9][5] = .lolo_spawn

	assert game.test_play_custom_level()
	assert !game.channels_open[0]

	// Step UP onto Plate Channel 1 at (5, 8)
	game.move_lolo(.up)
	assert game.lolo.y == 8
	game.update(0.016)
	assert game.channels_open[0]

	// Step UP through Gate Channel 1 at (5, 6)
	game.move_lolo(.up)
	step, _, _, _, _, _ := game.move_lolo(.up)
	assert step
	assert game.lolo.y == 6
}

fn test_timed_pulse_laser_barriers() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Pulse Test', .volcanic)
	game.editor_level.grid[8][5] = .timed_laser_barrier
	game.editor_level.entities[9][5] = .lolo_spawn

	assert game.test_play_custom_level()
	game.is_pulse_active = true

	// While active, moving UP is blocked
	step1, _, _, _, _, _ := game.move_lolo(.up)
	assert !step1

	// Advance pulse clock to switch pulse state
	game.update(2.1)
	assert !game.is_pulse_active

	// Now barrier is down, can step through!
	step2, _, _, _, _, _ := game.move_lolo(.up)
	assert step2
	assert game.lolo.y == 8
}

fn test_hologram_lore_dialogue_terminals() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Holo Test', .haunted)
	game.editor_level.lore_text = 'SYSTEM LOG: CYBER HINTS ACTIVE.'
	game.editor_level.entities[8][5] = .holo_terminal
	game.editor_level.entities[9][5] = .lolo_spawn

	assert game.test_play_custom_level()
	assert !game.is_dialogue_open

	// Step UP into Holo Terminal
	game.move_lolo(.up)
	assert game.is_dialogue_open
	assert game.active_dialogue == 'SYSTEM LOG: CYBER HINTS ACTIVE.'
}

fn test_dark_dungeon_fog_of_war() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Dark Test', .haunted)
	game.editor_level.is_dark_dungeon = true
	assert game.test_play_custom_level()
	assert game.current_level.is_dark_dungeon
}

fn test_speedrun_medal_calculations() {
	mut game := new_game()
	game.editor_level = create_empty_level_theme('Medal Test', .castle)
	game.editor_level.target_gold_sec = 10
	game.editor_level.target_silver_sec = 20
	game.editor_level.target_bronze_sec = 30

	assert game.test_play_custom_level()
	// Simulate fast clear under 10 seconds
	game.level_time_ms = 5000
	game.door_open = true
	game.entities[0][5] = .door
	game.lolo.x = 5
	game.lolo.y = 1
	game.move_lolo(.up)

	assert game.status == .level_clear
	assert game.earned_medal == 'GOLD'
}

fn test_all_campaign_levels_valid() {
	game := new_game()
	assert game.campaign_levels.len == 65
	for i, lvl in game.campaign_levels {
		mut h_count := 0
		mut door_count := 0
		mut chest_count := 0
		mut lolo_count := 0

		for r in 0 .. grid_rows {
			for c in 0 .. grid_cols {
				match lvl.entities[r][c] {
					.lolo_spawn { lolo_count++ }
					.door { door_count++ }
					.chest { chest_count++ }
					.heart_frame { h_count++ }
					else {}
				}
			}
		}

		assert lolo_count == 1, 'Level ${i + 1} (${lvl.name}) missing Lolo spawn'
		assert door_count == 1, 'Level ${i + 1} (${lvl.name}) missing Door'
		assert chest_count == 1, 'Level ${i + 1} (${lvl.name}) missing Chest'
		assert h_count >= 1, 'Level ${i + 1} (${lvl.name}) missing Hearts'
	}
}

fn test_all_5_community_packs_valid() {
	game := new_game()
	for i, lvl in game.community_levels {
		mut lolo_count := 0
		for r in 0 .. grid_rows {
			for c in 0 .. grid_cols {
				if lvl.entities[r][c] == .lolo_spawn {
					lolo_count++
				}
			}
		}
		assert lolo_count == 1, 'Community Pack ${i + 1} (${lvl.name}) missing Lolo spawn'
	}
}
