module main

fn test_game_init_and_start() {
	mut game := new_yoshi_cookie_game()
	assert game.state == .title
	assert game.score == 0

	game.start_game(1, .med)
	assert game.state == .playing
	assert game.round == 1
	assert game.speed == .med
	assert game.count_cookies() > 0
	assert game.min_r >= 0 && game.max_r < 8
	assert game.min_c >= 0 && game.max_c < 8
}

fn test_row_shift_wrap_around() {
	mut game := new_yoshi_cookie_game()
	game.start_game(1, .low)
	game.clear_grid()

	game.min_r = 2
	game.max_r = 5
	game.min_c = 2
	game.max_c = 5

	game.grid[3][2] = .donut
	game.grid[3][3] = .heart
	game.grid[3][4] = .diamond
	game.grid[3][5] = .checkered

	// Shift Row 3 Right (dir: 1)
	game.shift_row(3, 1)
	assert game.grid[3][2] == .checkered
	assert game.grid[3][3] == .donut
	assert game.grid[3][4] == .heart
	assert game.grid[3][5] == .diamond

	// Shift Row 3 Left (dir: -1) -> Returns to original
	game.shift_row(3, -1)
	assert game.grid[3][2] == .donut
	assert game.grid[3][3] == .heart
	assert game.grid[3][4] == .diamond
	assert game.grid[3][5] == .checkered
}

fn test_col_shift_wrap_around() {
	mut game := new_yoshi_cookie_game()
	game.start_game(1, .low)
	game.clear_grid()

	game.min_r = 2
	game.max_r = 5
	game.min_c = 2
	game.max_c = 5

	game.grid[2][4] = .donut
	game.grid[3][4] = .heart
	game.grid[4][4] = .diamond
	game.grid[5][4] = .checkered

	// Shift Col 4 Down (dir: 1)
	game.shift_col(4, 1)
	assert game.grid[2][4] == .checkered
	assert game.grid[3][4] == .donut
	assert game.grid[4][4] == .heart
	assert game.grid[5][4] == .diamond

	// Shift Col 4 Up (dir: -1) -> Returns to original
	game.shift_col(4, -1)
	assert game.grid[2][4] == .donut
	assert game.grid[3][4] == .heart
	assert game.grid[4][4] == .diamond
	assert game.grid[5][4] == .checkered
}

fn test_horizontal_line_match_and_clear() {
	mut game := new_yoshi_cookie_game()
	game.start_game(1, .low)
	game.clear_grid()

	game.min_r = 2
	game.max_r = 3
	game.min_c = 2
	game.max_c = 4

	// Complete row of hearts in row 2
	game.grid[2][2] = .heart
	game.grid[2][3] = .heart
	game.grid[2][4] = .heart

	game.grid[3][2] = .donut
	game.grid[3][3] = .diamond
	game.grid[3][4] = .crescent

	matched := game.check_matches()
	assert matched == true
	assert game.matched_grid[2][2] == true
	assert game.matched_grid[2][3] == true
	assert game.matched_grid[2][4] == true
	assert game.matched_grid[3][2] == false

	game.clear_matched_cookies()
	assert game.grid[2][2] == .none
	assert game.grid[2][3] == .none
	assert game.grid[2][4] == .none
	assert game.grid[3][2] == .donut
	assert game.score > 0
}

fn test_vertical_line_match_with_wildcard() {
	mut game := new_yoshi_cookie_game()
	game.start_game(1, .low)
	game.clear_grid()

	game.min_r = 2
	game.max_r = 4
	game.min_c = 2
	game.max_c = 3

	// Column 3 has diamonds + yoshi wildcard star
	game.grid[2][3] = .diamond
	game.grid[3][3] = .yoshi_star // Wildcard!
	game.grid[4][3] = .diamond

	game.grid[2][2] = .donut
	game.grid[3][2] = .heart
	game.grid[4][2] = .checkered

	matched := game.check_matches()
	assert matched == true
	assert game.matched_grid[2][3] == true
	assert game.matched_grid[3][3] == true
	assert game.matched_grid[4][3] == true

	game.clear_matched_cookies()
	assert game.grid[2][3] == .none
	assert game.grid[3][3] == .none
	assert game.grid[4][3] == .none
	assert game.grid[2][2] == .donut
}

fn test_stage_clear_and_next_level() {
	mut game := new_yoshi_cookie_game()
	game.start_game(1, .low)
	game.clear_grid()

	assert game.count_cookies() == 0

	// Compact grid triggers stage clear when all cookies are gone
	game.compact_grid()
	assert game.state == .stage_clear
	assert game.stage_clear_timer > 0.0

	// Advance round
	game.next_level()
	assert game.round == 2
	assert game.state == .playing
	assert game.count_cookies() > 0
}

fn test_conveyor_injection() {
	mut game := new_yoshi_cookie_game()
	game.start_game(1, .low)
	game.clear_grid()

	game.min_r = 3
	game.max_r = 4
	game.min_c = 3
	game.max_c = 4

	game.conveyor_side = 0 // Top injection
	game.inject_conveyor_cookies()
	assert game.min_r == 2
	assert game.grid[2][3] != .none
	assert game.grid[2][4] != .none
}

fn test_sound_toggle_and_bgm_cycle() {
	mut sm := new_sound_manager()
	initial := sm.sound_enabled
	toggled := sm.toggle_sound()
	assert toggled != initial

	assert sm.bgm_type == .type_a
	sm.cycle_bgm()
	assert sm.bgm_type == .type_b
	sm.cycle_bgm()
	assert sm.bgm_type == .off
	sm.cycle_bgm()
	assert sm.bgm_type == .type_a
}

fn test_reserve_cookie_plate_swap() {
	mut game := new_yoshi_cookie_game()
	game.start_game(1, .low)
	game.clear_grid()

	game.min_r = 2
	game.max_r = 5
	game.min_c = 2
	game.max_c = 5
	game.cursor_r = 3
	game.cursor_c = 3

	game.grid[3][3] = .donut
	assert game.has_reserve == false

	// First reserve swap puts donut on plate and puts wildcard star on tray
	game.swap_reserve_cookie()
	assert game.has_reserve == true
	assert game.reserve_cookie == .donut
	assert game.grid[3][3] == .yoshi_star

	// Second reserve swap swaps wildcard star with plate donut
	game.swap_reserve_cookie()
	assert game.has_reserve == true
	assert game.reserve_cookie == .yoshi_star
	assert game.grid[3][3] == .donut
}

fn test_instant_conveyor_push() {
	mut game := new_yoshi_cookie_game()
	game.start_game(1, .low)
	game.clear_grid()

	game.min_r = 3
	game.max_r = 4
	game.min_c = 3
	game.max_c = 4
	game.conveyor_timer = 5.0
	score_before := game.score

	game.instant_conveyor_push()
	assert game.score == score_before + 50
	assert game.count_cookies() > 0
}
