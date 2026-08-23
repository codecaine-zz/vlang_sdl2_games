module main

fn test_is_prime() {
	assert is_prime(2) == true
	assert is_prime(3) == true
	assert is_prime(4) == false
	assert is_prime(5) == true
	assert is_prime(17) == true
	assert is_prime(25) == false
	assert is_prime(29) == true
	assert is_prime(1) == false
	assert is_prime(0) == false
}

fn test_is_multiple() {
	assert is_multiple(12, 3) == true
	assert is_multiple(12, 4) == true
	assert is_multiple(12, 5) == false
	assert is_multiple(25, 5) == true
	assert is_multiple(7, 3) == false
}

fn test_is_factor() {
	assert is_factor(3, 12) == true
	assert is_factor(4, 12) == true
	assert is_factor(5, 12) == false
	assert is_factor(1, 10) == true
	assert is_factor(10, 10) == true
}

fn test_inequality() {
	assert is_greater_than(25, 20) == true
	assert is_greater_than(15, 20) == false
	assert is_less_than(5, 10) == true
	assert is_less_than(15, 10) == false
}

fn test_game_initialization() {
	mut g := new_game(.multiples)
	assert g.lives == 3
	assert g.score == 0
	assert g.level == 1
	assert g.muncher.col == 0
	assert g.muncher.row == 0
	assert g.remaining_targets > 0
}

fn test_muncher_movement() {
	mut g := new_game(.multiples)
	assert g.muncher.col == 0
	assert g.muncher.row == 0

	// Boundary check moving left/up
	assert g.move_muncher(-1, 0) == false
	assert g.move_muncher(0, -1) == false

	// Moving right and down
	assert g.move_muncher(1, 0) == true
	assert g.muncher.col == 1
	assert g.move_muncher(0, 1) == true
	assert g.muncher.row == 1
}

fn test_munch_correct_and_incorrect() {
	mut g := new_game(.multiples)

	// Find a target cell and a non-target cell
	mut target_col := -1
	mut target_row := -1
	mut non_target_col := -1
	mut non_target_row := -1

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if g.grid[c][r].is_target && target_col == -1 {
				target_col = c
				target_row = r
			}
			if !g.grid[c][r].is_target && non_target_col == -1 {
				non_target_col = c
				non_target_row = r
			}
		}
	}

	// Munch target cell
	g.muncher.col = target_col
	g.muncher.row = target_row
	initial_score := g.score
	res1 := g.munch_current_cell()
	assert res1 == .correct
	assert g.score > initial_score
	assert g.grid[target_col][target_row].is_munched == true

	// Re-munching already munched cell
	res_dup := g.munch_current_cell()
	assert res_dup == .already_munched

	// Munch non-target cell
	g.muncher.col = non_target_col
	g.muncher.row = non_target_row
	initial_lives := g.lives
	res2 := g.munch_current_cell()
	assert res2 == .incorrect
	assert g.lives == initial_lives - 1
}

fn test_troggle_spawning_and_collision() {
	mut g := new_game(.multiples)
	assert g.troggles.len == 0

	g.spawn_troggle()
	assert g.troggles.len == 1

	// Calculate target position after troggle movement step
	mut target_c := g.troggles[0].col + g.troggles[0].dir_col
	mut target_r := g.troggles[0].row + g.troggles[0].dir_row
	if target_c < 0 || target_c >= grid_cols || target_r < 0 || target_r >= grid_rows {
		target_c = g.troggles[0].col - g.troggles[0].dir_col
		target_r = g.troggles[0].row - g.troggles[0].dir_row
	}

	g.muncher.col = target_c
	g.muncher.row = target_r
	g.troggles[0].move_timer = 0.0

	initial_lives := g.lives
	g.update(0.1)
	assert g.lives == initial_lives - 1
	// Muncher resets to (0,0) after getting eaten
	assert g.muncher.col == 0
	assert g.muncher.row == 0
}

fn test_mode_switching() {
	mut g := new_game(.multiples)
	assert g.mode == .multiples

	g.set_mode(.factors)
	assert g.mode == .factors
	assert g.rule.mode == .factors

	g.set_mode(.primes)
	assert g.mode == .primes
	assert g.rule.mode == .primes
}
