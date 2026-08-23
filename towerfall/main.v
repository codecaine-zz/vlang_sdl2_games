module main

import os
import sdl

const win_width = 800
const win_height = 576

fn main() {
	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		run_snapshot_mode()
		return
	}

	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to initialize SDL')
		return
	}
	defer { sdl.quit() }

	window := sdl.create_window(c'TowerFall Ascension - V & SDL2', sdl.windowpos_centered,
		sdl.windowpos_centered, win_width, win_height, u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable))

	if unsafe { window == nil } {
		eprintln('Failed to create window')
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		eprintln('Failed to create renderer')
		return
	}
	defer { sdl.destroy_renderer(renderer) }

	sdl.render_set_logical_size(renderer, win_width, win_height)

	mut tex_mgr := TextureManager{}
	tex_mgr.init(renderer)

	mut game := new_towerfall_game()
	mut running := true
	mut last_ticks := sdl.get_ticks()

	// Input Keys Tracker
	mut key_left := false
	mut key_right := false
	mut key_up := false
	mut key_down := false

	mut event := sdl.Event{}

	for running {
		now := sdl.get_ticks()
		dt := f64(now - last_ticks) / 1000.0
		last_ticks = now
		capped_dt := if dt > 0.05 { 0.05 } else { dt }

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.escape) {
						if game.mode != .menu {
							game.mode = .menu
						} else {
							running = false
						}
					} else if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.f5) {
						game.save_state()
					} else if sym == int(sdl.KeyCode.f9) {
						game.load_state()
					} else if game.mode == .menu {
						if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
							game.menu_selected = (game.menu_selected + 1) % 2
						} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
							game.menu_selected = (game.menu_selected + 1) % 2
						} else if sym == int(sdl.KeyCode._1) {
							game.start_quest()
						} else if sym == int(sdl.KeyCode._2) {
							game.start_versus()
						} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) || sym == int(sdl.KeyCode.j) {
							if game.menu_selected == 0 {
								game.start_quest()
							} else {
								game.start_versus()
							}
						}
					} else if game.mode != .menu {
						// Player 1 Movement Keys
						if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) { key_left = true }
						if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) { key_right = true }
						if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) { key_up = true }
						if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) { key_down = true }

						// Jump: Space / K
						if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.k) {
							if game.players.len > 0 {
								mut p := unsafe { &game.players[0] }
								if p.is_grounded {
									p.vy = -480.0
									game.sound_mgr.play_clip('jump')
								} else if p.is_wall_slide {
									p.vy = -440.0
									p.vx = f64(-p.wall_dir) * 320.0
									game.sound_mgr.play_clip('jump')
								}
							}
						}

						// Shoot Bow: J / L / Enter
						if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.l) || sym == int(sdl.KeyCode.@return) {
							if game.players.len > 0 {
								mut p := unsafe { &game.players[0] }
								game.shoot_arrow(mut p)
							}
						}

						// Dodge Dash: Shift / I
						if sym == int(sdl.KeyCode.lshift) || sym == int(sdl.KeyCode.rshift) || sym == int(sdl.KeyCode.i) {
							if game.players.len > 0 {
								mut p := unsafe { &game.players[0] }
								mut dx := 0.0
								mut dy := 0.0
								if key_left { dx = -1.0 }
								if key_right { dx = 1.0 }
								if key_up { dy = -1.0 }
								if key_down { dy = 1.0 }
								if dx == 0.0 && dy == 0.0 { dx = f64(p.facing) }
								game.dodge_dash(mut p, dx, dy)
							}
						}
					}
				}
				.keyup {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) { key_left = false }
					if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) { key_right = false }
					if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) { key_up = false }
					if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) { key_down = false }
				}
				else {}
			}
		}

		// Apply Continuous Movement Input to P1
		if game.mode != .menu && game.players.len > 0 {
			mut p := unsafe { &game.players[0] }
			if !p.is_dashing {
				if key_left {
					p.vx = -220.0
					p.facing = -1
				} else if key_right {
					p.vx = 220.0
					p.facing = 1
				}

				// Aim direction calculation
				mut ax := f64(p.facing)
				mut ay := 0.0
				if key_up { ay = -1.0 }
				if key_down { ay = 1.0 }
				if key_left || key_right { ax = if key_left { -1.0 } else { 1.0 } }
				p.aim_x = ax
				p.aim_y = ay
			}
		}

		game.update(capped_dt)
		game.sound_mgr.update_bgm(game.mode != .menu)
		render_towerfall_game(renderer, mut game, tex_mgr.sprite_texture)
		sdl.render_present(renderer)
		sdl.delay(16)
	}
}

fn toggle_fullscreen(window &sdl.Window) {
	flags := sdl.get_window_flags(window)
	if (flags & u32(sdl.WindowFlags.fullscreen_desktop)) != 0 || (flags & u32(sdl.WindowFlags.fullscreen)) != 0 {
		sdl.set_window_fullscreen(window, 0)
	} else {
		sdl.set_window_fullscreen(window, u32(sdl.WindowFlags.fullscreen_desktop))
	}
}

fn run_snapshot_mode() {
	sdl.init(sdl.init_video)
	surface := sdl.create_rgb_surface(0, win_width, win_height, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
	renderer := sdl.create_software_renderer(surface)
	mut tex_mgr := TextureManager{}
	tex_mgr.init(renderer)
	mut game := new_towerfall_game()
	game.start_quest()
	render_towerfall_game(renderer, mut game, tex_mgr.sprite_texture)
	os.mkdir_all('screenshots') or {}
	sdl.save_bmp(surface, 'screenshots/towerfall.bmp'.str)
	sdl.destroy_renderer(renderer)
	sdl.free_surface(surface)
	sdl.quit()
	println('Saved snapshot to screenshots/towerfall.bmp')
}
