module main

import os
import sdl

fn main() {
	if os.args.contains("--snapshot") || os.args.contains("--snap") || os.getenv("SNAPSHOT") == "1" {
		if sdl.init(sdl.init_video) != 0 { return }
		defer { sdl.quit() }
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut game := new_towerdefense_game()
		game.state = .playing
		game.score = 12400
		game.place_turret(1, 1, .laser)
		game.place_turret(3, 4, .cannon)
		render_towerdefense_game(s_renderer, mut game, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/towerdefense.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}
	sdl.init(sdl.init_video | sdl.init_audio)
	defer { sdl.quit() }

	window := sdl.create_window(
		'Cyber Defense Tower Defense'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		800,
		600,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } { return }
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } { return }
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, 800, 600)

	mut tex_mgr := TowerDefenseTextureManager{}
	tex_mgr.init(renderer)

	mut game := new_towerdefense_game()

	mut running := true
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()

	for running {
		for sdl.poll_event(&event) != 0 {
			match unsafe { event.@type } {
				.quit { running = false }
				.mousebuttondown {
					if event.button.button == u8(sdl.button_left) {
						if game.state == .menu || game.state == .game_over || game.state == .victory {
							game.reset_game()
						} else {
							mx := event.button.x
							my := event.button.y
							gx := (mx - offset_x) / tile_size
							gy := (my - offset_y) / tile_size

							if gx >= 0 && gx < grid_cols && gy >= 0 && gy < grid_rows {
								game.selected_gx = gx
								game.selected_gy = gy
								game.place_turret(gx, gy, game.selected_type)
							}
						}
					}
				}
				.keydown {
					sym := event.key.keysym.sym
					// 1. Select Turret Type: 1, 2, 3, Keypad 1/2/3, L, C, F
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode._1) || sym == int(sdl.KeyCode.kp_1) || sym == int(sdl.KeyCode.l) {
						game.selected_type = .laser
					} else if sym == int(sdl.KeyCode._2) || sym == int(sdl.KeyCode.kp_2) || sym == int(sdl.KeyCode.c) {
						game.selected_type = .cannon
					} else if sym == int(sdl.KeyCode._3) || sym == int(sdl.KeyCode.kp_3) || sym == int(sdl.KeyCode.f) {
						game.selected_type = .frost
					}
					// 2. Navigation: Arrow Keys & WASD
					else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						if game.selected_gx > 0 { game.selected_gx-- }
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						if game.selected_gx < grid_cols - 1 { game.selected_gx++ }
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						if game.selected_gy > 0 { game.selected_gy-- }
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						if game.selected_gy < grid_rows - 1 { game.selected_gy++ }
					}
					// 3. Action / Build: SPACE, ENTER, KP_ENTER, B
					else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) || sym == int(sdl.KeyCode.kp_enter) || sym == int(sdl.KeyCode.b) {
						if game.state == .menu || game.state == .game_over || game.state == .victory {
							game.reset_game()
						} else if game.state == .playing {
							game.place_turret(game.selected_gx, game.selected_gy, game.selected_type)
						}
					}
					// 4. Upgrade Turret: U
					else if sym == int(sdl.KeyCode.u) {
						game.upgrade_turret(game.selected_gx, game.selected_gy)
					}
					// 5. Sell Turret: X, DELETE, BACKSPACE
					else if sym == int(sdl.KeyCode.x) || sym == int(sdl.KeyCode.delete) || sym == int(sdl.KeyCode.backspace) {
						game.sell_turret(game.selected_gx, game.selected_gy)
					}
					// 6. Pause Game: P
					else if sym == int(sdl.KeyCode.p) {
						if game.state == .playing { game.state = .paused }
						else if game.state == .paused { game.state = .playing }
					}
					// 7. Restart Game: R
					else if sym == int(sdl.KeyCode.r) {
						game.reset_game()
					}
					// 8. Toggle Mute: M
					else if sym == int(sdl.KeyCode.m) {
						game.sound_mgr.toggle_sound()
					}
					// 9. Quit Game: ESCAPE
					else if sym == int(sdl.KeyCode.escape) {
						running = false
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
		game.sound_mgr.update_bgm(game.state == .playing)
		render_towerdefense_game(renderer, mut game, tex_mgr.sprite_texture)

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
