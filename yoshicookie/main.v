module main

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

		mut game := new_yoshi_cookie_game()
		game.start_game(2, .med)
		game.score = 7200
		game.high_score = 15000
		game.cookies_cleared = 38
		game.cursor_r = 3
		game.cursor_c = 4

		// Setup visually attractive layout
		game.min_r = 1
		game.max_r = 5
		game.min_c = 1
		game.max_c = 5

		game.grid[1][1] = .donut
		game.grid[1][2] = .heart
		game.grid[1][3] = .diamond
		game.grid[1][4] = .checkered
		game.grid[1][5] = .crescent

		game.grid[2][1] = .heart
		game.grid[2][2] = .heart
		game.grid[2][3] = .heart
		game.grid[2][4] = .heart
		game.grid[2][5] = .heart // Full matching row!

		game.grid[3][1] = .donut
		game.grid[3][2] = .diamond
		game.grid[3][3] = .yoshi_star
		game.grid[3][4] = .donut
		game.grid[3][5] = .checkered

		game.grid[4][1] = .checkered
		game.grid[4][2] = .crescent
		game.grid[4][3] = .donut
		game.grid[4][4] = .diamond
		game.grid[4][5] = .heart

		game.grid[5][1] = .crescent
		game.grid[5][2] = .donut
		game.grid[5][3] = .heart
		game.grid[5][4] = .checkered
		game.grid[5][5] = .yoshi_star

		// Add score popup & crumb burst particles
		game.add_crumb_particles(388.0, 266.0, 16)
		game.add_score_popup(388.0, 230.0, '+500', Color{ r: 255, g: 240, b: 40, a: 255 })

		render_yoshi_cookie_game(s_renderer, mut game, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/yoshicookie.bmp'.str)
		return
	}

	// Normal Window
	window := sdl.create_window(
		'Yoshi\'s Cookie (1992 Nintendo Arcade)'.str,
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

	mut tex_mgr := YoshiCookieTextureManager{}
	tex_mgr.init(renderer)

	mut game := new_yoshi_cookie_game()

	mut last_ticks := sdl.get_ticks()

	for {
		mut event := sdl.Event{}
		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					return
				}
				.mousebuttondown {
					game.handle_mouse_down(event.button.x, event.button.y)
				}
				.mousemotion {
					game.handle_mouse_motion(event.motion.x, event.motion.y)
				}
				.mousebuttonup {
					game.handle_mouse_up()
				}
				.keydown {
					sym := event.key.keysym.sym
					// Left
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						if game.state == .title {
							if game.round > 1 { game.round-- }
						} else {
							game.key_left = true
							game.move_cursor(0, -1)
						}
					}
					// Right
					else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						if game.state == .title {
							if game.round < 10 { game.round++ }
						} else {
							game.key_right = true
							game.move_cursor(0, 1)
						}
					}
					// Up
					else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
						game.key_up = true
						game.move_cursor(-1, 0)
					}
					// Down
					else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						game.key_down = true
						game.move_cursor(1, 0)
					}
					// Direct Shift Keys (IJKL): Shift without holding grab!
					else if sym == int(sdl.KeyCode.i) {
						game.shift_col(game.cursor_c, -1)
					} else if sym == int(sdl.KeyCode.k) {
						game.shift_col(game.cursor_c, 1)
					} else if sym == int(sdl.KeyCode.j) && !game.key_grab {
						game.shift_row(game.cursor_r, -1)
					} else if sym == int(sdl.KeyCode.l) {
						game.shift_row(game.cursor_r, 1)
					}
					// Fast Conveyor Push & Action (Space / Return)
					else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
						if game.state == .title {
							game.start_game(game.round, game.speed)
						} else if game.state == .stage_clear {
							game.next_level()
						} else if game.state == .game_over {
							game.reset_to_title()
						} else if game.state == .playing {
							game.instant_conveyor_push()
						}
					}
					// Grab Modifier (Z)
					else if sym == int(sdl.KeyCode.z) {
						game.key_grab = true
					}
					// Reserve Cookie Plate (LShift / RShift / H)
					else if sym == int(sdl.KeyCode.lshift) || sym == int(sdl.KeyCode.rshift) || sym == int(sdl.KeyCode.h) {
						if game.state == .playing {
							game.swap_reserve_cookie()
						}
					}
					// Match Hint Guide Toggle (G)
					else if sym == int(sdl.KeyCode.g) {
						game.hints_enabled = !game.hints_enabled
					}
					// Cycle Soundtrack (T / B)
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
						if game.state in [.playing, .clearing_matches, .compacting] {
							game.state = .paused
						} else if game.state == .paused {
							game.state = .playing
						}
					}
					// Mute Audio
					else if sym == int(sdl.KeyCode.m) {
						game.sound_mgr.toggle_sound()
					}
					// CRT Filter
					else if sym == int(sdl.KeyCode.c) {
						game.crt_filter = !game.crt_filter
					}
					// Restart
					else if sym == int(sdl.KeyCode.r) {
						game.start_game(1, game.speed)
					}
					// Escape
					else if sym == int(sdl.KeyCode.escape) {
						return
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						game.key_left = false
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						game.key_right = false
					} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
						game.key_up = false
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						game.key_down = false
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.z) {
						game.key_grab = false
					}
				}
				else {}
			}
		}

		current_ticks := sdl.get_ticks()
		mut dt := f32(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		if dt > 0.05 {
			dt = 0.05
		}

		game.update(dt)

		render_yoshi_cookie_game(renderer, mut game, tex_mgr.sprite_texture)
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
