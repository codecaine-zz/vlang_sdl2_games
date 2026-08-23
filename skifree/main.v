module main

import math
import os
import sdl

const win_w = 840
const win_h = 600

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      SkiGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game:      new_ski_game()
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

		mut snap_game := new_ski_game()
		snap_game.mode = .free_ski
		snap_game.pose = .ski_straight
		snap_game.vy = 280.0
		snap_game.distance_m = 1420
		snap_game.score = 3500
		snap_game.time_elapsed = 48.0
		snap_game.banner_timer = 0.0
		snap_game.banner_text = ''
		snap_game.yeti.active = true
		snap_game.yeti.x = snap_game.x + 90.0
		snap_game.yeti.y = snap_game.y - 140.0

		render_ski_game(renderer, mut snap_game, win_w, win_h)
		sdl.save_bmp(surface, 'screenshots/skifree.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'SkiFree Extreme - Classic 1991 Shareware Winter Sports'.str,
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
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.steer_left()
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.steer_right()
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.steer_down()
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.game.steer_up()
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.pose == .stopped {
							app.game.steer_down()
						} else if app.game.pose != .airborne && !app.game.is_trick_pose(app.game.pose) {
							app.game.pose = .airborne
							app.game.air_time = 0.0
							app.sound_mgr.play_jump()
						}
					} else if sym == int(sdl.KeyCode.m) {
						app.game.mode = match app.game.mode {
							.free_ski { GameMode.slalom }
							.slalom { GameMode.tree_slalom }
							.tree_slalom { GameMode.yeti_survival }
							.yeti_survival { GameMode.free_ski }
						}
						app.game.reset_game()
					} else if sym == int(sdl.KeyCode.r) {
						app.game.reset_game()
					} else if sym == int(sdl.KeyCode.o) {
						app.sound_mgr.toggle_sound()
					}
				}
				else {}
			}
		}

		app.game.update(dt)

		// Play sound events
		if app.game.sound_event != '' {
			match app.game.sound_event {
				'jump' { app.sound_mgr.play_jump() }
				'trick' { app.sound_mgr.play_trick_chime() }
				'crash' { app.sound_mgr.play_crash() }
				'gate' { app.sound_mgr.play_gate_bell() }
				'yeti_roar' { app.sound_mgr.play_yeti_roar() }
				'yeti_crunch' { app.sound_mgr.play_yeti_crunch() }
				else {}
			}
		}

		render_ski_game(renderer, mut app.game, win_w, win_h)
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
