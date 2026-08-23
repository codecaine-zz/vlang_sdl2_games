module main

import math
import os
import sdl

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio) != 0 {
		eprintln('Failed to initialize SDL')
		return
	}
	defer { sdl.quit() }

	// Snapshot capture for docs/tests
	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } {
			return
		}
		defer { sdl.free_surface(surface) }

		s_renderer := sdl.create_software_renderer(surface)
		if unsafe { s_renderer == nil } {
			return
		}
		defer { sdl.destroy_renderer(s_renderer) }

		mut game := new_dr_mario_game()
		game.init_textures(s_renderer)
		defer {
			if game.sprite_texture != unsafe { nil } {
				sdl.destroy_texture(game.sprite_texture)
			}
		}
		game.start_game(5, .med)
		game.score = 8400
		game.high_score = 16800

		// Setup active falling pill
		game.active_pill = ActivePill{
			x: 3
			y: 6
			c1: .red
			c2: .blue
			orientation: .horizontal
		}
		game.has_active_pill = true
		game.next_c1 = .yellow
		game.next_c2 = .red

		// Setup bottom pile
		game.grid[15][0] = Cell{ cell_type: .pill_single, color: .red }
		game.grid[15][1] = Cell{ cell_type: .pill_single, color: .red }
		game.grid[15][2] = Cell{ cell_type: .pill_single, color: .red }
		game.grid[15][3] = Cell{ cell_type: .virus, color: .red } // 4th match!

		game.grid[14][1] = Cell{ cell_type: .pill_left, color: .blue }
		game.grid[14][2] = Cell{ cell_type: .pill_right, color: .yellow }

		game.grid[13][4] = Cell{ cell_type: .pill_top, color: .blue }
		game.grid[14][4] = Cell{ cell_type: .pill_bottom, color: .blue }
		game.grid[15][4] = Cell{ cell_type: .virus, color: .blue }

		game.grid[15][6] = Cell{ cell_type: .virus, color: .yellow }
		game.grid[15][7] = Cell{ cell_type: .pill_single, color: .yellow }

		// Add score popup & match burst particles
		game.add_particles(372.0, 480.0, 14, Color{ r: 255, g: 60, b: 60, a: 255 })
		game.add_score_popup(372.0, 440.0, '+200', Color{ r: 255, g: 240, b: 40, a: 255 })

		render_dr_mario_game(s_renderer, mut game)
		sdl.save_bmp(surface, 'screenshots/drmario.bmp'.str)
		return
	}

	// Normal Window
	window := sdl.create_window(
		'Dr. Mario (1990 Nintendo Classic Recreation)'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		800,
		600,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
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
	sdl.render_set_logical_size(renderer, 800, 600)

	mut game := new_dr_mario_game()
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
					// Left
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						if game.state == .title {
							if game.level > 0 { game.level-- }
						} else {
							game.key_left = true
							game.move_horizontal(-1)
						}
					}
					// Right
					else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						if game.state == .title {
							if game.level < 20 { game.level++ }
						} else {
							game.key_right = true
							game.move_horizontal(1)
						}
					}
					// Soft Drop
					else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						game.key_down = true
					}
					// Hard Drop (Space / Return)
					else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
						if game.state == .title {
							game.start_game(game.level, game.speed)
						} else if game.state == .stage_clear {
							game.next_level()
						} else if game.state == .game_over {
							game.reset_to_title()
						} else if game.state == .playing {
							game.hard_drop()
						}
					}
					// Rotate CW (W / Up / J / Z)
					else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						if game.state == .title {
							game.start_game(game.level, game.speed)
						} else if game.state == .stage_clear {
							game.next_level()
						} else if game.state == .game_over {
							game.reset_to_title()
						} else {
							game.rotate_pill(true)
						}
					}
					// Rotate CCW (K / X)
					else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.x) {
						game.rotate_pill(false)
					}
					// Hold Capsule (LShift / RShift / H)
					else if sym == int(sdl.KeyCode.lshift) || sym == int(sdl.KeyCode.rshift) || sym == int(sdl.KeyCode.h) {
						if game.state == .playing {
							game.hold_current_pill()
						}
					}
					// Toggle Ghost Projection (G)
					else if sym == int(sdl.KeyCode.g) {
						game.ghost_enabled = !game.ghost_enabled
					}
					// Cycle BGM Soundtrack (T / B)
					else if sym == int(sdl.KeyCode.t) || sym == int(sdl.KeyCode.b) {
						game.sound_mgr.cycle_bgm()
					}
					// Speed Options
					else if sym == int(sdl.KeyCode._1) {
						game.speed = .low
					} else if sym == int(sdl.KeyCode._2) {
						game.speed = .med
					} else if sym == int(sdl.KeyCode._3) {
						game.speed = .hi
					}
					// Pause
					else if sym == int(sdl.KeyCode.p) {
						if game.state in [.playing, .clearing_matches, .cascade_falling] {
							game.state = .paused
						} else if game.state == .paused {
							game.state = .playing
						}
					}
					// Sound toggle
					else if sym == int(sdl.KeyCode.m) {
						game.sound_mgr.toggle_sound()
					}
					// CRT Scanlines toggle
					else if sym == int(sdl.KeyCode.c) {
						game.crt_filter = !game.crt_filter
					}
					// Restart
					else if sym == int(sdl.KeyCode.r) {
						game.reset_to_title()
					}
					// Escape
					else if sym == int(sdl.KeyCode.escape) {
						if game.state == .title {
							running = false
						} else {
							game.reset_to_title()
						}
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						game.key_left = false
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						game.key_right = false
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						game.key_down = false
					}
				}
				else {}
			}
		}

		current_ticks := sdl.get_ticks()
		dt := f32(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		clamped_dt := f32(math.min(f64(dt), 0.05))

		game.update(clamped_dt)
		render_dr_mario_game(renderer, mut game)
		prod_fx_render(renderer)
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
