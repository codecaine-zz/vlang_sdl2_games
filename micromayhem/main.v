module main

import math
import os
import sdl

const win_w = 940
const win_h = 660

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      MicroMayhemGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
}

fn new_app() App {
	return App{
		game:      new_micromayhem_game()
		sound_mgr: new_sound_manager()
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	// Snapshot mode for README showcase
	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_micromayhem_game()
		snap_game.phase = .playing
		snap_game.current_micro = .defuse_bomb
		snap_game.bomb_target_wire = 1
		snap_game.instruction = 'CUT GREEN WIRE! [1-3]'
		snap_game.score = 750
		snap_game.streak = 5
		snap_game.speed_multiplier = 1.4
		snap_game.game_timer = 2.8

		render_micromayhem_game(renderer, mut snap_game, win_w, win_h, 0, 0)
		sdl.save_bmp(surface, 'screenshots/micromayhem.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Micro Mayhem - WarioWare-Style Party Gauntlet'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_w,
		win_h,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } {
		eprintln('Failed to create SDL window')
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		eprintln('Failed to create SDL renderer')
		return
	}
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

	app.window = window
	app.renderer = renderer

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousemotion {
					app.mouse_x = event.motion.x
					app.mouse_y = event.motion.y
				}
				.mousebuttondown {
					if event.button.button == sdl.button_left {
						if app.game.phase == .title || app.game.phase == .game_over {
							app.game.start_game()
							app.sound_mgr.play_speedup()
						} else if app.game.phase == .playing {
							app.game.handle_click(f64(event.button.x), f64(event.button.y))
						}
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					match sym {
						int(sdl.KeyCode.f11) {
							toggle_fullscreen(window)
						}
						int(sdl.KeyCode.escape) {
							running = false
						}
						int(sdl.KeyCode.space) {
							if app.game.phase == .title || app.game.phase == .game_over {
								app.game.start_game()
								app.sound_mgr.play_speedup()
							} else if app.game.phase == .playing {
								app.game.handle_key_action(0)
							}
						}
						int(sdl.KeyCode.r) {
							app.game.start_game()
						}
						int(sdl.KeyCode.v), int(sdl.KeyCode.o) {
							app.sound_mgr.toggle_sound()
						}
						int(sdl.KeyCode._1) { app.game.handle_key_action(1) }
						int(sdl.KeyCode._2) { app.game.handle_key_action(2) }
						int(sdl.KeyCode._3) { app.game.handle_key_action(3) }
						int(sdl.KeyCode.a), int(sdl.KeyCode.left) { app.game.handle_key_action(-1) }
						int(sdl.KeyCode.d), int(sdl.KeyCode.right) { app.game.handle_key_action(1) }
						else {}
					}
				}
				else {}
			}
		}

		app.game.update(dt, f64(app.mouse_x))

		// Sound event triggers
		if app.game.sound_event != '' {
			ev := app.game.sound_event
			app.game.sound_event = ''
			match ev {
				'tick' { app.sound_mgr.play_tick(600.0) }
				'win' { app.sound_mgr.play_win() }
				'fail' { app.sound_mgr.play_fail() }
				'speedup' { app.sound_mgr.play_speedup() }
				'pop' { app.sound_mgr.play_pop() }
				else {}
			}
		}

		sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
		sdl.render_clear(renderer)

		render_micromayhem_game(renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)

		prod_fx_render(renderer)
		sdl.render_present(renderer)
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
