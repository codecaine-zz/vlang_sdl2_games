module main

import os
import sdl

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio) != 0 {
		return
	}
	defer { sdl.quit() }

	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut game := new_galaga_game()
		game.init_textures(s_renderer)
		game.state = .playing
		game.score = 24800
		game.high_score = 50000
		game.player.is_dual = true
		game.player.x = 400.0
		game.player.y = 520.0
		game.player.invuln_timer = 0.0

		// Set enemies in iconic battle formation
		game.enemies.clear()
		mut id_c := 0
		// 4 Boss Commanders
		for col in 0 .. 4 {
			game.enemies << Enemy{
				id: id_c, enemy_type: .boss, mode: .formation,
				home_x: 280.0 + f32(col) * 80.0, home_y: 100.0,
				x: 280.0 + f32(col) * 80.0, y: 100.0,
				hp: 2, active: true
			}
			id_c++
		}
		// 8 Red Goei Moths
		for col in 0 .. 8 {
			game.enemies << Enemy{
				id: id_c, enemy_type: .goei, mode: .formation,
				home_x: 190.0 + f32(col) * 60.0, home_y: 150.0,
				x: 190.0 + f32(col) * 60.0, y: 150.0,
				hp: 1, active: true
			}
			id_c++
		}
		// 10 Blue Zako Bees
		for col in 0 .. 10 {
			game.enemies << Enemy{
				id: id_c, enemy_type: .zako, mode: .formation,
				home_x: 130.0 + f32(col) * 60.0, home_y: 200.0,
				x: 130.0 + f32(col) * 60.0, y: 200.0,
				hp: 1, active: true
			}
			id_c++
		}
		// Swooping Boss Attacking
		game.enemies << Enemy{
			id: id_c, enemy_type: .boss, mode: .swooping,
			home_x: 360.0, home_y: 100.0,
			x: 360.0, y: 320.0,
			hp: 2, active: true
		}
		// Player Dual Lasers
		game.player_bullets << Bullet{ x: 388.0, y: 380.0, vy: -600.0, is_enemy: false, active: true }
		game.player_bullets << Bullet{ x: 412.0, y: 380.0, vy: -600.0, is_enemy: false, active: true }
		game.player_bullets << Bullet{ x: 388.0, y: 260.0, vy: -600.0, is_enemy: false, active: true }
		game.player_bullets << Bullet{ x: 412.0, y: 260.0, vy: -600.0, is_enemy: false, active: true }

		render_galaga_game(s_renderer, mut game)
		sdl.save_bmp(surface, 'screenshots/galaga.bmp'.str)
		if game.sprite_texture != unsafe { nil } {
			sdl.destroy_texture(game.sprite_texture)
		}
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'Galaga Arcade Space Shooter'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		800,
		600,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } {
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		return
	}
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, 800, 600)

	mut game := new_galaga_game()
	game.init_textures(renderer)
	defer {
		if game.sprite_texture != unsafe { nil } {
			sdl.destroy_texture(game.sprite_texture)
		}
		game.sound_mgr.cleanup()
	}

	mut running := true
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()

	for running {
		for sdl.poll_event(&event) != 0 {
			match unsafe { event.@type } {
				.quit {
					running = false
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						game.key_left = true
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						game.key_right = true
					} else if sym == int(sdl.KeyCode.space) {
						if game.state == .menu || game.state == .game_over {
							game.reset_game()
						} else {
							game.key_fire = true
						}
					} else if sym == int(sdl.KeyCode.p) {
						if game.state == .playing {
							game.state = .paused
						} else if game.state == .paused {
							game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.r) {
						game.reset_game()
					} else if sym == int(sdl.KeyCode.m) {
						game.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						game.key_left = false
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						game.key_right = false
					} else if sym == int(sdl.KeyCode.space) {
						game.key_fire = false
					}
				}
				else {}
			}
		}

		current_ticks := sdl.get_ticks()
		dt := f32(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks

		capped_dt := if dt > 0.05 { f32(0.05) } else { dt }
		game.update(capped_dt)
		game.sound_mgr.update_bgm(game.state != .game_over)
		render_galaga_game(renderer, mut game)

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
