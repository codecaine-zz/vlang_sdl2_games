module main

import math
import os
import sdl

const win_w = 920
const win_h = 700

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      LightCyclesGame
	sound_mgr SoundManager
	particles []CrashParticle
}

fn new_app() App {
	return App{
		game:      new_lightcycles_game()
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

		mut snap_game := new_lightcycles_game()
		snap_game.p1_score = 3
		snap_game.p2_score = 2

		// Simulate nice ribbon trails
		for step_i in 0 .. 45 {
			if step_i == 15 {
				snap_game.set_p1_dir(.up)
				snap_game.set_p2_dir(.down)
			} else if step_i == 30 {
				snap_game.set_p1_dir(.right)
				snap_game.set_p2_dir(.left)
			}
			snap_game.step_timer = snap_game.step_interval
			snap_game.update(0.001)
		}

		render_lightcycles_arena(renderer, &snap_game, win_w, win_h, []CrashParticle{})
		bmp_path := 'screenshots/lightcycles.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Tron Light Cycles - Cyber Arena Pro'.str,
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

		update_crash_particles(mut app.particles, dt)

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
						app.game.reset_match()
					} else if sym == int(sdl.KeyCode.m) {
						app.game.mode = if app.game.mode == .pve { GameMode.pvp } else { GameMode.pve }
						app.game.reset_match()
					} else if sym == int(sdl.KeyCode.d) {
						app.game.diff = match app.game.diff {
							.easy { Difficulty.normal }
							.normal { Difficulty.master }
							.master { Difficulty.easy }
						}
					} else if sym == int(sdl.KeyCode.s) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.state == .round_over {
							app.game.reset_round()
						} else if app.game.state == .match_over {
							app.game.reset_match()
						} else {
							app.game.p1.is_boosting = true
							app.sound_mgr.play_boost_sound()
						}
					}
					// P1 controls (WASD / Arrows)
					else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
						if app.game.set_p1_dir(.up) { app.sound_mgr.play_turn_sound() }
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						if app.game.set_p1_dir(.down) { app.sound_mgr.play_turn_sound() }
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						if app.game.set_p1_dir(.left) { app.sound_mgr.play_turn_sound() }
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						if app.game.set_p1_dir(.right) { app.sound_mgr.play_turn_sound() }
					}
					// P2 Controls in PvP mode (IJKL + RShift)
					else if app.game.mode == .pvp {
						if sym == int(sdl.KeyCode.i) {
							if app.game.set_p2_dir(.up) { app.sound_mgr.play_turn_sound() }
						} else if sym == int(sdl.KeyCode.k) {
							if app.game.set_p2_dir(.down) { app.sound_mgr.play_turn_sound() }
						} else if sym == int(sdl.KeyCode.j) {
							if app.game.set_p2_dir(.left) { app.sound_mgr.play_turn_sound() }
						} else if sym == int(sdl.KeyCode.l) {
							if app.game.set_p2_dir(.right) { app.sound_mgr.play_turn_sound() }
						} else if sym == int(sdl.KeyCode.rshift) {
							app.game.p2.is_boosting = true
							app.sound_mgr.play_boost_sound()
						}
					}
				}
				.keyup {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.space) {
						app.game.p1.is_boosting = false
					} else if sym == int(sdl.KeyCode.rshift) {
						app.game.p2.is_boosting = false
					}
				}
				else {}
			}
		}

		ev := app.game.update(dt)
		if ev.crashed {
			app.sound_mgr.play_crash_sound()
			// Crash particles
			col := if app.game.round_winner == 1 { Color{r: 255, g: 110, b: 30} } else { Color{r: 30, g: 220, b: 255} }
			app.particles << create_crash_particles(f64(win_w / 2), f64(win_h / 2), col)
		}
		if ev.round_ended && app.game.state == .match_over {
			app.sound_mgr.play_win_sound()
		}

		render_lightcycles_arena(app.renderer, &app.game, win_w, win_h, app.particles)
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
