module main

fn test_player_creation_and_starting_weapons() {
	p1 := create_player(0, .antonio, 100.0, 100.0)
	assert p1.name == 'Antonio'
	assert p1.weapons.len == 1
	assert p1.weapons[0].kind == .whip

	p2 := create_player(1, .imelda, 100.0, 100.0)
	assert p2.name == 'Imelda'
	assert p2.weapons.len == 1
	assert p2.weapons[0].kind == .magic_wand

	p3 := create_player(2, .pasqualina, 100.0, 100.0)
	assert p3.weapons[0].kind == .holy_bible

	p4 := create_player(3, .gennaro, 100.0, 100.0)
	assert p4.weapons[0].kind == .knife
}

fn test_distance_and_normalization() {
	d := dist(0.0, 0.0, 3.0, 4.0)
	assert int(d) == 5

	nx, ny := normalize(10.0, 0.0)
	assert int(nx) == 1
	assert int(ny) == 0

	zx, zy := normalize(0.0, 0.0)
	assert zx == 0.0 && zy == 0.0
}

fn test_weapon_creation_and_passives() {
	mut w := create_weapon(.whip)
	assert w.level == 1
	assert w.damage >= 20.0

	mut p := create_player(0, .antonio, 500.0, 500.0)
	assert p.get_passive_level(.spinach) == 0

	p.passives << Passive{kind: .spinach, level: 2}
	assert p.get_passive_level(.spinach) == 2
}

fn test_level_up_and_upgrade_selection() {
	mut g := new_game()
	g.start_game(.antonio, .imelda, false)
	assert g.players[0].level == 1

	g.trigger_level_up(0)
	assert g.state == .level_up
	assert g.upgrade_cards.len >= 1

	g.select_upgrade(0)
	assert g.state == .playing
}

fn test_enemy_creation_and_types() {
	bat := create_enemy(.bat, 100.0, 100.0, false)
	assert bat.hp >= 8.0
	assert bat.speed >= 110.0

	reaper := create_enemy(.reaper_boss, 100.0, 100.0, true)
	assert reaper.is_boss
	assert reaper.hp >= 1500.0
}

fn test_sound_bgm_cycle() {
	mut sm := new_sound_manager()
	assert sm.bgm_track == .gothic_rondo
	sm.cycle_bgm()
	assert sm.bgm_track == .vampires_eclipse
	sm.cycle_bgm()
	assert sm.bgm_track == .bloodlust_symphony
	sm.cycle_bgm()
	assert sm.bgm_track == .off
	sm.cycle_bgm()
	assert sm.bgm_track == .gothic_rondo
}

fn test_weapon_evolutions_and_pickups() {
	mut p := create_player(0, .antonio, 200.0, 200.0)
	p.weapons[0].level = 8
	p.passives << Passive{kind: .spinach, level: 1}

	evo, ok := get_weapon_evolution(.whip, &p)
	assert ok
	assert evo == .bloody_tear

	bt := create_weapon(.bloody_tear)
	assert bt.is_evolved
	assert bt.damage >= 40.0

	mut g := new_game()
	g.start_game(.antonio, .imelda, false)
	g.breakables << BreakableProp{x: 150.0, y: 150.0, hp: 1.0, is_urn: false}
	assert g.breakables.len >= 1

	// Test floor pickups collection
	g.collect_floor_pickup(.floor_chicken, 0)
	assert g.players[0].hp == 120.0

	g.collect_floor_pickup(.freeze_watch, 0)
	assert g.frozen_timer >= 5.0

	// Test Ultimate Ability
	assert g.players[0].ultimate_meter >= 100.0
	g.activate_ultimate(0)
	assert g.players[0].ultimate_meter == 0.0
	assert g.projectiles.len >= 16

	// Test Massive Horde Weapons
	nuke := create_weapon(.cataclysm_nuke)
	assert nuke.damage >= 100.0
	laser := create_weapon(.prismatic_laser)
	assert laser.speed >= 600.0

	// Test Speed Cycle
	assert g.game_speed == 1.0
	g.cycle_speed()
	assert g.game_speed == 1.5
	g.cycle_speed()
	assert g.game_speed == 2.0
	g.cycle_speed()
	assert g.game_speed == 3.0
	g.cycle_speed()
	assert g.game_speed == 1.0

	// Test Difficulty Cycle and Scaling
	assert g.difficulty == .hard
	g.cycle_difficulty()
	assert g.difficulty == .inferno
	inferno_bat := g.create_scaled_enemy(.bat, 100.0, 100.0, false, false)
	assert inferno_bat.hp >= 30.0
	g.cycle_difficulty()
	assert g.difficulty == .normal
}
