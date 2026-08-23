module main

import math
import os
import sdl

const win_w = 840
const win_h = 680

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      QbertGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game:      new_qbert_game()
		sound_mgr: new_sound_manager()
	}
}

fn (mut app App) do_hop(dir HopDir) {
	valid, on_disc := app.game.try_hop(dir)
	if valid {
		if on_disc {
			app.sound_mgr.play_disc_sound()
		} else if app.game.state == .cursing {
			app.sound_mgr.play_curse_sound()
		} else {
			app.sound_mgr.play_hop_sound()
		}

		if app.game.state == .level_cleared {
			app.sound_mgr.play_win_sound()
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

		mut snap_game := new_qbert_game()
		snap_game.score = 3850
		snap_game.lives = 3

		// Flip several cubes to golden yellow
		snap_game.cubes[0] = 1
		snap_game.cubes[1] = 1
		snap_game.cubes[2] = 1
		snap_game.cubes[3] = 1
		snap_game.cubes[4] = 1
		snap_game.cubes[7] = 1
		snap_game.cubes[8] = 1
		snap_game.cubes[11] = 1
		snap_game.cubes[12] = 1

		// Position Q*bert, Coily and red ball
		snap_game.player.r = 3
		snap_game.player.c = 2
		snap_game.coily.is_alive = true
		snap_game.coily_hatched = true
		snap_game.coily.r = 5
		snap_game.coily.c = 4
		snap_game.red_ball.is_alive = true
		snap_game.red_ball.r = 4
		snap_game.red_ball.c = 1

		render_qbert_game(renderer, &snap_game, win_w, win_h)
		bmp_path := 'screenshots/qbert.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Q*bert 2.5D Isometric - Arcade Classic'.str,
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
						if app.game.state == .level_cleared {
							app.game.round_num++
							app.game.reset_round()
						} else if app.game.state == .game_over {
							app.game.reset_game()
						}
					}
					// Isometric Diagonal Controls:
					// Up-Left: Q, Keypad 7, Up, Left
					else if sym == int(sdl.KeyCode.q) || sym == int(sdl.KeyCode.kp_7) || sym == int(sdl.KeyCode.w) {
						app.do_hop(.up_left)
					}
					// Up-Right: E, Keypad 9, Up
					else if sym == int(sdl.KeyCode.e) || sym == int(sdl.KeyCode.kp_9) || sym == int(sdl.KeyCode.up) {
						app.do_hop(.up_right)
					}
					// Down-Left: A, Keypad 1, Left, Down
					else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.kp_1) || sym == int(sdl.KeyCode.left) {
						app.do_hop(.down_left)
					}
					// Down-Right: D, Keypad 3, Right, Down
					else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.kp_3) || sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.down) {
						app.do_hop(.down_right)
					}
				}
				else {}
			}
		}

		ev := app.game.update(dt)
		if ev.hit_enemy {
			app.sound_mgr.play_curse_sound()
		}
		if ev.cleared {
			app.sound_mgr.play_win_sound()
		}

		render_qbert_game(app.renderer, &app.game, win_w, win_h)
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
