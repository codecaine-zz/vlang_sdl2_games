module main

fn test_lunarlander_initialization() {
	mut g := new_lunarlander_game()
	assert g.fuel == 100.0
	assert g.lives == 3
	assert g.pads.len == 3
	assert g.terrain_points.len > 5
}

fn test_lunarlander_gravity() {
	mut g := new_lunarlander_game()
	initial_vy := g.vy
	g.update(0.1)
	assert g.vy > initial_vy
}

fn test_lunarlander_thrust() {
	mut g := new_lunarlander_game()
	g.key_thrust = true
	initial_fuel := g.fuel
	g.update(0.1)
	assert g.fuel < initial_fuel
}

fn test_lunarlander_reset() {
	mut g := new_lunarlander_game()
	g.fuel = 20.0
	g.reset_game()
	assert g.fuel == 100.0
	assert g.lives == 3
}
