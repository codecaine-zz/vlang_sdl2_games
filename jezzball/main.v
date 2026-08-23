module main

import math
import os
import rand
import sdl

const win_w = 880
const win_h = 600

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      JezzGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
}

fn new_app() App {
	return App{
		game:      new_jezz_game()
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

		mut snap_game := new_jezz_game()
		snap_game.start_wall(arena_w / 2, arena_h / 2)
		for _ in 0 .. 45 {
			snap_game.update(0.016)
		}

		render_jezz_game(renderer, mut snap_game, win_w, win_h, win_w / 2, win_h / 2)
		sdl.save_bmp(surface, 'screenshots/jezzball.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'JezzBall Pro - Classic 1992 Kinetic Containment Puzzle'.str,
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

		ox := (win_w - arena_w) / 2
		oy := 60

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousemotion {
					app.mouse_x = int(event.motion.x)
					app.mouse_y = int(event.motion.y)
				}
				.mousebuttondown {
					mx := int(event.button.x)
					my := int(event.button.y)
					app.mouse_x = mx
					app.mouse_y = my

					if event.button.button == u8(sdl.button_left) {
						if app.game.is_won {
							app.game.init_level(app.game.level + 1)
						} else if app.game.is_game_over {
							app.game.init_level(1)
							app.game.lives = 3
							app.game.score = 0
						} else {
							play_x := mx - ox
							play_y := my - oy
							if app.game.start_wall(play_x, play_y) {
								app.sound_mgr.play_wall_build()
							}
						}
					} else if event.button.button == u8(sdl.button_right) {
						app.game.toggle_orientation()
						app.sound_mgr.play_ball_bounce(4)
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.is_won {
							app.game.init_level(app.game.level + 1)
						} else if app.game.is_game_over {
							app.game.init_level(1)
							app.game.lives = 3
							app.game.score = 0
						} else {
							app.game.toggle_orientation()
							app.sound_mgr.play_ball_bounce(4)
						}
					} else if sym == int(sdl.KeyCode.r) {
						app.game.init_level(app.game.level)
					} else if sym == int(sdl.KeyCode.n) {
						app.game.init_level(app.game.level + 1)
					} else if sym == int(sdl.KeyCode.o) {
						app.sound_mgr.toggle_sound()
					}
				}
				else {}
			}
		}

		app.game.update(dt)

		// Play triggered audio events
		if app.game.sound_event != '' {
			match app.game.sound_event {
				'bounce' { app.sound_mgr.play_ball_bounce(rand.intn(8) or { 0 }) }
				'wall_build' { app.sound_mgr.play_wall_build() }
				'wall_lock' { app.sound_mgr.play_wall_lock() }
				'wall_shatter' { app.sound_mgr.play_wall_shatter() }
				'capture' { app.sound_mgr.play_capture_sweep() }
				'win' { app.sound_mgr.play_win_fanfare() }
				'lose' { app.sound_mgr.play_lose_buzzer() }
				else {}
			}
		}

		render_jezz_game(renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)
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
