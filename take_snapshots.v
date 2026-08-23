module main

import sdl
import galaga
import bomberman
import frogger
import lunarlander
import digdug
import missilecommand
import donkeykong
import towerdefense
import shinobi
import rain

fn capture_game_snapshot(game_name string, render_fn fn(&sdl.Renderer)) {
	surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
	if unsafe { surface == nil } { return }
	defer { sdl.free_surface(surface) }

	renderer := sdl.create_software_renderer(surface)
	if unsafe { renderer == nil } { return }
	defer { sdl.destroy_renderer(renderer) }

	render_fn(renderer)

	bmp_path := "screenshots/${game_name}.bmp"
	sdl.save_bmp(surface, bmp_path.str)
}

fn main() {
	sdl.init(sdl.init_video)
	defer { sdl.quit() }

	// 1. Galaga (Iconic Space Shooter with Dual Ship & Formation)
	mut g_galaga := galaga.new_galaga_game()
	g_galaga.state = .playing
	g_galaga.score = 24800
	g_galaga.high_score = 50000
	g_galaga.player.is_dual = true
	g_galaga.player.x = 400.0
	g_galaga.player.y = 520.0
	g_galaga.player.invuln_timer = 0.0

	// Set enemies in iconic battle formation
	g_galaga.enemies.clear()
	mut id_c := 0
	// 4 Boss Commanders
	for col in 0 .. 4 {
		g_galaga.enemies << galaga.Enemy{
			id: id_c, enemy_type: .boss, mode: .formation,
			home_x: 280.0 + f32(col) * 80.0, home_y: 100.0,
			x: 280.0 + f32(col) * 80.0, y: 100.0,
			hp: 2, active: true
		}
		id_c++
	}
	// 8 Red Goei Moths
	for col in 0 .. 8 {
		g_galaga.enemies << galaga.Enemy{
			id: id_c, enemy_type: .goei, mode: .formation,
			home_x: 190.0 + f32(col) * 60.0, home_y: 150.0,
			x: 190.0 + f32(col) * 60.0, y: 150.0,
			hp: 1, active: true
		}
		id_c++
	}
	// 10 Blue Zako Bees
	for col in 0 .. 10 {
		g_galaga.enemies << galaga.Enemy{
			id: id_c, enemy_type: .zako, mode: .formation,
			home_x: 130.0 + f32(col) * 60.0, home_y: 200.0,
			x: 130.0 + f32(col) * 60.0, y: 200.0,
			hp: 1, active: true
		}
		id_c++
	}
	// Swooping Boss Attacking
	g_galaga.enemies << galaga.Enemy{
		id: id_c, enemy_type: .boss, mode: .swooping,
		home_x: 360.0, home_y: 100.0,
		x: 360.0, y: 320.0,
		hp: 2, active: true
	}
	// Player Dual Lasers
	g_galaga.player_bullets << galaga.Bullet{ x: 388.0, y: 380.0, vy: -600.0, is_enemy: false, active: true }
	g_galaga.player_bullets << galaga.Bullet{ x: 412.0, y: 380.0, vy: -600.0, is_enemy: false, active: true }
	g_galaga.player_bullets << galaga.Bullet{ x: 388.0, y: 260.0, vy: -600.0, is_enemy: false, active: true }
	g_galaga.player_bullets << galaga.Bullet{ x: 412.0, y: 260.0, vy: -600.0, is_enemy: false, active: true }

	capture_game_snapshot("galaga", fn [mut g_galaga] (r &sdl.Renderer) {
		galaga.render_galaga_game(r, mut g_galaga)
	})

	// 2. Bomberman (Action Maze with Bombs and Enemies)
	mut g_bm := bomberman.new_bomberman_game()
	g_bm.state = .playing
	g_bm.score = 6200
	capture_game_snapshot("bomberman", fn [mut g_bm] (r &sdl.Renderer) {
		bomberman.render_bomberman_game(r, mut g_bm)
	})

	// 3. Frogger (Highway Traffic & River Logs)
	mut g_fr := frogger.new_frogger_game()
	g_fr.state = .playing
	g_fr.score = 3450
	capture_game_snapshot("frogger", fn [mut g_fr] (r &sdl.Renderer) {
		frogger.render_frogger_game(r, mut g_fr)
	})

	// 4. Lunar Lander (Vector Moon Landing)
	mut g_ll := lunarlander.new_lunarlander_game()
	g_ll.state = .playing
	g_ll.score = 1200
	capture_game_snapshot("lunarlander", fn [mut g_ll] (r &sdl.Renderer) {
		lunarlander.render_lunarlander_game(r, mut g_ll)
	})

	// 5. Dig Dug (Subterranean Tunnels & Enemies)
	mut g_dd := digdug.new_digdug_game()
	g_dd.state = .playing
	g_dd.score = 8900
	capture_game_snapshot("digdug", fn [mut g_dd] (r &sdl.Renderer) {
		digdug.render_digdug_game(r, mut g_dd)
	})

	// 6. Missile Command (City Defense & ICBM Flak)
	mut g_mc := missilecommand.new_missilecommand_game()
	g_mc.state = .playing
	g_mc.score = 15400
	capture_game_snapshot("missilecommand", fn [mut g_mc] (r &sdl.Renderer) {
		missilecommand.render_missilecommand_game(r, mut g_mc)
	})

	// 7. Donkey Kong (Arcade Slanted Girders, Barrels, Pauline & DK)
	mut g_dk := donkeykong.new_donkeykong_game()
	g_dk.state = .playing
	g_dk.score = 14200
	g_dk.high_score = 30000
	g_dk.player_x = 220.0
	g_dk.player_y = 420.0
	g_dk.hammer_timer = 4.0
	g_dk.dk_anim_timer = 1.0

	// Active rolling barrels on multiple tiers
	g_dk.barrels.clear()
	g_dk.barrels << donkeykong.Barrel{ x: 480.0, y: 224.0, vx: -140.0, vy: 0.0, b_type: .normal, active: true }
	g_dk.barrels << donkeykong.Barrel{ x: 300.0, y: 324.0, vx: 140.0, vy: 0.0, b_type: .blue, active: true }
	g_dk.barrels << donkeykong.Barrel{ x: 550.0, y: 424.0, vx: -140.0, vy: 0.0, b_type: .normal, active: true }
	g_dk.barrels << donkeykong.Barrel{ x: 160.0, y: 524.0, vx: -140.0, vy: 0.0, b_type: .normal, active: true }

	// Fireball climbing ladder
	g_dk.fireballs.clear()
	g_dk.fireballs << donkeykong.Fireball{ x: 120.0, y: 380.0, vx: 0.0, vy: -40.0, is_climbing: true, active: true }

	capture_game_snapshot("donkeykong", fn [mut g_dk] (r &sdl.Renderer) {
		donkeykong.render_donkeykong_game(r, mut g_dk)
	})

	// 8. Tower Defense
	mut g_td := towerdefense.new_towerdefense_game()
	g_td.state = .playing
	g_td.place_turret(1, 1, .laser)
	g_td.place_turret(3, 4, .cannon)
	capture_game_snapshot("towerdefense", fn [mut g_td] (r &sdl.Renderer) {
		towerdefense.render_towerdefense_game(r, mut g_td)
	})

	// 9. Shinobi (Cyber Ninja Runner)
	mut g_sh := shinobi.new_shinobi_game()
	g_sh.state = .playing
	g_sh.score = 7800
	capture_game_snapshot("shinobi", fn [mut g_sh] (r &sdl.Renderer) {
		shinobi.render_shinobi_game(r, mut g_sh)
	})

	// 10. Rain Simulator & M4 Benchmark
	mut g_rain := rain.new_rain_game()
	g_rain.update(0.016)
	capture_game_snapshot("rain", fn [mut g_rain] (r &sdl.Renderer) {
		rain.render_rain_game(r, mut g_rain)
	})
}
