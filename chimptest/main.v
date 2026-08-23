module main

import math
import os
import sdl

const win_w = 880
const win_h = 600

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      ChimpGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game:      new_chimp_game()
		sound_mgr: new_sound_manager()
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_chimp_game()
		snap_game.level = 7
		snap_game.start_level()
		snap_game.strikes = 1

		render_chimp_test(renderer, &snap_game, win_w, win_h, 3, 2)
		sdl.save_bmp(surface, 'screenshots/chimptest.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Chimp Test Pro - Spatial Working Memory Benchmark'.str,
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
		_ = math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		mut mouse_x := 0
		mut mouse_y := 0
		sdl.get_mouse_state(&mouse_x, &mouse_y)

		hover_gx, hover_gy := get_chimp_grid_coords_at(mouse_x, mouse_y, win_w, win_h)

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.r) {
						app.game.reset_game()
					} else if sym == int(sdl.KeyCode.s) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.state == .level_failed || app.game.state == .benchmark_over {
							app.game.handle_cell_click(0, 0)
						}
					}
				}
				.mousebuttondown {
					if event.button.button == 1 {
						if app.game.state == .level_failed || app.game.state == .benchmark_over {
							app.game.handle_cell_click(0, 0)
						} else if hover_gx >= 0 && hover_gy >= 0 {
							_, ev := app.game.handle_cell_click(hover_gx, hover_gy)
							if ev.tile_clicked > 0 {
								app.sound_mgr.play_tile_chime(ev.tile_clicked)
							}
							if ev.strike_taken {
								app.sound_mgr.play_strike_buzzer()
							}
							if ev.level_cleared {
								app.sound_mgr.play_level_clear()
							}
						}
					}
				}
				else {}
			}
		}

		render_chimp_test(app.renderer, &app.game, win_w, win_h, hover_gx, hover_gy)
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
