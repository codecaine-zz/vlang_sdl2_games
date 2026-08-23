module main

import math
import os
import sdl

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      GoldMinerGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game:      new_gold_miner_game()
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
		surface := sdl.create_rgb_surface(0, world_w, world_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, world_w, world_h)

		mut snap_game := new_gold_miner_game()
		snap_game.money = 1350
		snap_game.target_money = 1500
		snap_game.level = 2
		snap_game.time_left = 38.0
		snap_game.dynamite_count = 2

		// Shoot claw grabbing medium gold nugget
		snap_game.claw.angle = 0.38
		snap_game.claw.len = 280.0
		snap_game.claw.state = .retracting
		snap_game.claw.hooked_item = 1 // gold_med

		render_goldminer_game(renderer, &snap_game, world_w, world_h)
		bmp_path := 'screenshots/goldminer.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Gold Miner Classic - Winch & Shop Arcade'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		world_w,
		world_h,
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
	sdl.render_set_logical_size(renderer, world_w, world_h)

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
				.mousebuttondown {
					if event.button.button == sdl.button_left {
						if app.game.state == .won_level {
							app.game.level++
							app.game.reset_level()
						} else if app.game.state == .game_over {
							app.game.reset_game()
						} else {
							if app.game.launch_claw() {
								app.sound_mgr.play_claw_shoot_sound()
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
						app.game.reset_game()
					} else if sym == int(sdl.KeyCode.s) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.space) {
						if app.game.state == .won_level {
							app.game.level++
							app.game.reset_level()
						} else if app.game.state == .game_over {
							app.game.reset_game()
						} else {
							if app.game.launch_claw() {
								app.sound_mgr.play_claw_shoot_sound()
							}
						}
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						if app.game.use_dynamite() {
							app.sound_mgr.play_dynamite_sound()
						}
					}
				}
				else {}
			}
		}

		ev := app.game.update(dt)
		if ev.caught_gold || ev.caught_diamond {
			app.sound_mgr.play_gold_catch_sound()
		}
		if ev.item_reeled {
			app.sound_mgr.play_coin_sound()
		}
		if ev.tnt_exploded {
			app.sound_mgr.play_dynamite_sound()
		}
		if ev.won_level {
			app.sound_mgr.play_win_sound()
		}

		render_goldminer_game(app.renderer, &app.game, world_w, world_h)
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
