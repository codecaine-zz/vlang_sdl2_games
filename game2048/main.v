module main

import math
import os
import sdl

const win_w = 600
const win_h = 700

struct App {
mut:
	window     &sdl.Window   = unsafe { nil }
	renderer   &sdl.Renderer = unsafe { nil }
	game       Game2048
	sound_mgr  SoundManager
	particles  []MergeParticle
	drag_start_x int
	drag_start_y int
	is_dragging  bool
}

fn new_app() App {
	return App{
		game:      new_game_2048()
		sound_mgr: new_sound_manager()
	}
}

fn (mut app App) handle_slide(dir Direction) {
	moved, _, max_merged := app.game.slide(dir)
	if moved {
		if max_merged > 0 {
			app.sound_mgr.play_merge_sound(max_merged)
			// Spawn merge burst in center
			col, _ := get_tile_color(max_merged)
			app.particles << create_merge_burst(f64(win_w / 2), f64(win_h / 2), col)
		} else {
			app.sound_mgr.play_slide_sound()
		}

		if app.game.state == .won && !app.game.keep_playing {
			app.sound_mgr.play_win_sound()
		} else if app.game.state == .game_over {
			app.sound_mgr.play_game_over_sound()
		}
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

		mut snap_game := new_game_2048()
		// Setup rich colorful board
		snap_game.grid = [
			[2, 4, 8, 16],
			[32, 64, 128, 256],
			[512, 1024, 2048, 4096],
			[0, 2, 4, 8],
		]
		snap_game.score = 28640
		snap_game.best_score = 34500

		render_game_2048(renderer, &snap_game, win_w, win_h, []MergeParticle{})
		bmp_path := 'screenshots/game2048.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'2048 Neon Pulse - Sliding Puzzle'.str,
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

		update_merge_particles(mut app.particles, dt)

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousebuttondown {
					if event.button.button == u8(sdl.button_left) {
						app.drag_start_x = event.button.x
						app.drag_start_y = event.button.y
						app.is_dragging = true
					}
				}
				.mousebuttonup {
					if event.button.button == u8(sdl.button_left) && app.is_dragging {
						app.is_dragging = false
						dx := event.button.x - app.drag_start_x
						dy := event.button.y - app.drag_start_y
						min_drag := 30
						abs_dx := if dx < 0 { -dx } else { dx }
						abs_dy := if dy < 0 { -dy } else { dy }
						if abs_dx > abs_dy {
							if dx > min_drag {
								app.handle_slide(.right)
							} else if dx < -min_drag {
								app.handle_slide(.left)
							}
						} else {
							if dy > min_drag {
								app.handle_slide(.down)
							} else if dy < -min_drag {
								app.handle_slide(.up)
							}
						}
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.r) {
						app.game.reset()
					} else if sym == int(sdl.KeyCode.u) {
						app.game.undo()
					} else if sym == int(sdl.KeyCode.s) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.state == .won {
							app.game.keep_playing = true
							app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.handle_slide(.up)
					} else if sym == int(sdl.KeyCode.down) {
						app.handle_slide(.down)
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.handle_slide(.left)
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.handle_slide(.right)
					}
				}
				else {}
			}
		}

		render_game_2048(app.renderer, &app.game, win_w, win_h, app.particles)
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
